require "llvm/core"


module Stone
  # Runtime Type Information (RTTI) infrastructure.
  # Generates global type constants in LLVM IR for runtime type introspection.
  #
  # Type kind enum:
  #   0 = primitive (Int, Bool, String, Null)
  #   1 = record
  #   2 = union
  #   3 = function
  #   4 = type (metatype)
  class RTTI

    KIND_PRIMITIVE = 0
    KIND_RECORD = 1
    KIND_UNION = 2
    KIND_FUNCTION = 3
    KIND_TYPE = 4

    def initialize(mod)
      @mod = mod
    end

    def setup
      define_type_struct
      generate_primitive_type_constants
    end

    # Get or create a type constant for the given Stone type
    def self.type_constant_for(mod, type)
      name = type_constant_name(type)
      mod.globals[name] || create_type_constant(mod, type)
    end

    def self.type_constant_name(type)
      "Stone.Type.#{type.name}"
    end

    private def define_type_struct
      @type_struct = self.class.type_struct_type
    end

    # Cache the struct type at the class level since it's the same for all modules
    def self.type_struct_type
      @type_struct_type ||= create_type_struct_type
    end

    def self.create_type_struct_type
      # %Stone.Type = type { ptr, i64, i8, ptr }
      # Fields: name (string ptr), size (bytes), kind (enum), fields (FieldList ptr)
      LLVM::Type.struct([
        LLVM::Type.pointer,  # name - pointer to null-terminated string
        LLVM::Int64.type,    # size - size in bytes
        LLVM::Int8.type,     # kind - type kind enum
        LLVM::Type.pointer   # fields - pointer to FieldList (or null for primitives)
      ], false)
    end

    # %Stone.FieldList = type { ptr, ptr, ptr }
    # Fields: name (string ptr), field_type (Type ptr), tail (FieldList ptr or null)
    def self.field_list_struct_type
      @field_list_struct_type ||= LLVM::Type.struct([
        LLVM::Type.pointer,  # name - pointer to null-terminated string
        LLVM::Type.pointer,  # field_type - pointer to Type constant
        LLVM::Type.pointer   # tail - pointer to next FieldList (or null)
      ], false)
    end

    private def type_struct
      @type_struct ||= self.class.type_struct_type
    end

    private def generate_primitive_type_constants
      generate_type_constant("Int", 8, KIND_PRIMITIVE)
      generate_type_constant("Bool", 1, KIND_PRIMITIVE)
      generate_type_constant("String", 8, KIND_PRIMITIVE)  # pointer size
      generate_type_constant("Null", 0, KIND_PRIMITIVE)
      generate_type_constant("Type", 8, KIND_TYPE)  # pointer size
    end

    private def generate_type_constant(name, size, kind, fields_ptr = nil)
      name_global = create_name_string(name)
      fields_value = fields_ptr || LLVM::Type.pointer.null_pointer
      values = [name_global, LLVM::Int64.from_i(size), LLVM::Int8.from_i(kind), fields_value]
      add_type_global("Stone.Type.#{name}", values)
    end

    private def add_type_global(constant_name, values)
      @mod.globals.add(type_struct, constant_name).tap do |global|
        global.initializer = LLVM::ConstantStruct.named_const(type_struct, values)
        global.linkage = :internal
        global.global_constant = true
      end
    end

    private def create_name_string(name)
      string_name = "Stone.Type.#{name}.name"
      @mod.globals[string_name] || create_string_constant(string_name, name)
    end

    private def create_string_constant(global_name, value)
      array_type = LLVM::Type.array(LLVM::Int8.type, value.bytesize + 1)
      @mod.globals.add(array_type, global_name).tap do |global|
        global.initializer = LLVM::ConstantArray.string(value, true)
        global.linkage = :private
        global.global_constant = true
      end
    end

    # Generate a type constant for a record type with field information
    def self.generate_record_type_constant(mod, record_name, size_bytes, fields = [])
      rtti = new(mod)
      rtti.__send__(:define_type_struct)
      fields_ptr = rtti.__send__(:generate_field_list, record_name, fields)
      rtti.__send__(:generate_type_constant, record_name, size_bytes, KIND_RECORD, fields_ptr)
    end

    private def generate_field_list(record_name, fields)
      return LLVM::Type.pointer.null_pointer if fields.empty?

      # Generate field entries in reverse order so we can link them correctly
      field_entries = []
      fields.reverse_each.with_index do |field, reverse_index|
        index = fields.length - 1 - reverse_index
        rest_ptr = field_entries.last || LLVM::Type.pointer.null_pointer
        entry = generate_field_list_entry(record_name, field, index, rest_ptr)
        field_entries << entry
      end

      # Return the first field entry (which is last in our reversed list)
      field_entries.last
    end

    private def generate_field_list_entry(record_name, field, index, rest_ptr)
      name_global = create_field_name_string(record_name, field[:name])
      type_ptr = field_type_constant(field[:type])
      values = [name_global, type_ptr, rest_ptr]
      add_field_list_global("Stone.Field.#{record_name}.#{index}.#{field[:name]}", values)
    end

    private def field_type_constant(field_type_name)
      field_type = Stone::Type::Registry.lookup(field_type_name) || Stone::Type::Int
      self.class.type_constant_for(@mod, field_type)
    end

    private def add_field_list_global(constant_name, values)
      struct = self.class.field_list_struct_type
      @mod.globals.add(struct, constant_name).tap do |global|
        global.initializer = LLVM::ConstantStruct.named_const(struct, values)
        global.linkage = :internal
        global.global_constant = true
      end
    end

    private def create_field_name_string(record_name, field_name)
      string_name = "Stone.Field.#{record_name}.#{field_name}.name"
      @mod.globals[string_name] || create_string_constant(string_name, field_name)
    end

    private_class_method def self.create_type_constant(mod, type)
      rtti = new(mod)
      rtti.__send__(:define_type_struct)
      size, kind = type_size_and_kind(type)
      rtti.__send__(:generate_type_constant, type.name, size, kind)
      mod.globals[type_constant_name(type)]
    end

    private_class_method def self.type_size_and_kind(type)
      return [primitive_size(type), KIND_PRIMITIVE] if type.primitive?
      return [0, KIND_RECORD] if type.record?
      return [0, KIND_UNION] if type.union?
      return [8, KIND_FUNCTION] if type.function?
      return [8, KIND_TYPE] if type == Stone::Type::Type

      [0, KIND_PRIMITIVE]
    end

    private_class_method def self.primitive_size(type)
      case type.name
      when "Int" then 8
      when "Bool" then 1
      when "String" then 8
      when "Null" then 0
      else 0
      end
    end

  end
end
