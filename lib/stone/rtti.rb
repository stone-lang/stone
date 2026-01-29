require "llvm/core"
require "stone/libc"


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

    # Struct field indices within %Stone.Type
    TYPE_STRUCT_KIND_INDEX = 2
    TYPE_STRUCT_EQUALS_FN_INDEX = 4

    def initialize(mod)
      @mod = mod
    end

    def setup
      define_primitive_equals_functions
      define_union_equals_function
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

    # Cache the struct type at the class level since it's the same for all modules
    def self.type_struct_type
      @type_struct_type ||= create_type_struct_type
    end

    def self.create_type_struct_type
      # %Stone.Type = type { ptr, i64, i8, ptr, ptr }
      # Fields: name (string ptr), size (bytes), kind (enum), fields (FieldList ptr), equals_fn
      LLVM::Type.struct([
        LLVM::Type.pointer,  # name - pointer to null-terminated string
        LLVM::Int64.type,    # size - size in bytes
        LLVM::Int8.type,     # kind - type kind enum
        LLVM::Type.pointer,  # fields - pointer to FieldList (or null for primitives)
        LLVM::Type.pointer   # equals_fn - pointer to type-specific equality function
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

    # The function type for all equals_fn functions: (ptr, ptr) -> i1
    def self.equals_fn_type
      @equals_fn_type ||= LLVM::Type.function(
        [LLVM::Type.pointer, LLVM::Type.pointer],
        LLVM::Int1.type
      )
    end

    # Tagged equality signature: (tag_a, value_a, tag_b, value_b) -> i1
    def self.tagged_equals_fn_type
      @tagged_equals_fn_type ||= LLVM::Type.function(
        [LLVM::Type.pointer, LLVM::Type.pointer, LLVM::Type.pointer, LLVM::Type.pointer],
        LLVM::Int1.type
      )
    end

    # Load the equals_fn pointer from an RTTI type tag struct
    def self.load_equals_fn(builder, type_tag_ptr)
      fn_ptr_ptr = builder.struct_gep2(type_struct_type, type_tag_ptr, TYPE_STRUCT_EQUALS_FN_INDEX, "fn_ptr_ptr")
      builder.load2(LLVM::Type.pointer, fn_ptr_ptr, "fn_ptr")
    end

    private def type_struct
      @type_struct ||= self.class.type_struct_type
    end

    private def define_primitive_equals_functions
      @int_equals_fn = define_icmp_equals("__Int_equals__", LLVM::Int64.type)
      @bool_equals_fn = define_icmp_equals("__Bool_equals__", LLVM::Int1.type)
      @string_equals_fn = define_string_equals
      @null_equals_fn = define_null_equals
      @type_equals_fn = define_icmp_equals("__Type_equals__", LLVM::Type.pointer)
    end

    private def define_icmp_equals(name, load_type)
      @mod.functions.add(name, self.class.equals_fn_type).tap do |func|
        func.basic_blocks.append("entry").build do |b|
          a = b.load2(load_type, func.params[0], "a")
          val_b = b.load2(load_type, func.params[1], "b")
          b.ret(b.icmp(:eq, a, val_b, "eq"))
        end
      end
    end

    private def define_string_equals
      strcmp_func = Stone::LibC.get_or_declare_strcmp(@mod)
      @mod.functions.add("__String_equals__", self.class.equals_fn_type).tap do |func|
        build_string_equals_body(func, strcmp_func)
      end
    end

    private def build_string_equals_body(func, strcmp_func)
      func.basic_blocks.append("entry").build do |b|
        str1 = b.load2(LLVM::Type.pointer, func.params[0], "str1")
        str2 = b.load2(LLVM::Type.pointer, func.params[1], "str2")
        strcmp_result = b.call(strcmp_func, str1, str2, "strcmp_result")
        b.ret(b.icmp(:eq, strcmp_result, LLVM::Int32.from_i(0), "eq"))
      end
    end

    private def define_null_equals
      @mod.functions.add("__Null_equals__", self.class.equals_fn_type).tap do |func|
        func.basic_blocks.append("entry").build do |b|
          b.ret(LLVM::TRUE) # Both are Null type, always equal
        end
      end
    end

    # Union equality: compare type tags, then dispatch to type-specific equals_fn.
    # For record types, loads heap pointers from payloads before dispatch.
    private def define_union_equals_function
      @mod.functions.add("__union_equals__", self.class.tagged_equals_fn_type).tap do |func|
        build_union_equals_body(func)
      end
    end

    private def build_union_equals_body(func)
      blocks = create_union_equals_blocks(func)
      build_union_tag_compare(blocks, func)
      build_union_null_fn_guard(blocks, func)
      build_union_kind_dispatch(blocks, func)
      build_union_prim_dispatch(blocks, func)
      build_union_record_dispatch(blocks, func)
      blocks[:not_equal].build { |b| b.ret(LLVM::FALSE) }
    end

    private def create_union_equals_blocks(func)
      {
        entry: func.basic_blocks.append("entry"),
        same_type: func.basic_blocks.append("same_type"),
        check_kind: func.basic_blocks.append("check_kind"),
        prim_path: func.basic_blocks.append("prim_path"),
        record_path: func.basic_blocks.append("record_path"),
        not_equal: func.basic_blocks.append("not_equal")
      }
    end

    private def build_union_tag_compare(blocks, func)
      blocks[:entry].build do |b|
        tags_eq = b.icmp(:eq, func.params[0], func.params[2], "tags_eq")
        b.cond(tags_eq, blocks[:same_type], blocks[:not_equal])
      end
    end

    private def build_union_null_fn_guard(blocks, func)
      blocks[:same_type].build do |b|
        fn_ptr = self.class.load_equals_fn(b, func.params[0])
        fn_is_null = b.icmp(:eq, fn_ptr, LLVM::Type.ptr.null, "fn_is_null")
        b.cond(fn_is_null, blocks[:not_equal], blocks[:check_kind])
      end
    end

    # Records store heap pointers in union payloads, requiring an extra load indirection.
    # All other types (primitives, metatypes) store values directly, so they use prim_path.
    private def build_union_kind_dispatch(blocks, func)
      blocks[:check_kind].build do |b|
        kind_ptr = b.struct_gep2(type_struct, func.params[0], TYPE_STRUCT_KIND_INDEX, "kind_ptr")
        kind = b.load2(LLVM::Int8.type, kind_ptr, "kind")
        is_record = b.icmp(:eq, kind, LLVM::Int8.from_i(KIND_RECORD), "is_record")
        b.cond(is_record, blocks[:record_path], blocks[:prim_path])
      end
    end

    private def build_union_prim_dispatch(blocks, func)
      blocks[:prim_path].build do |b|
        fn_ptr = self.class.load_equals_fn(b, func.params[0])
        result = b.call2(self.class.equals_fn_type, fn_ptr, func.params[1], func.params[3], "prim_eq")
        b.ret(result)
      end
    end

    private def build_union_record_dispatch(blocks, func)
      blocks[:record_path].build do |b|
        fn_ptr = self.class.load_equals_fn(b, func.params[0])
        rec_a, rec_b = load_record_pointers(b, func)
        result = b.call2(self.class.equals_fn_type, fn_ptr, rec_a, rec_b, "rec_eq")
        b.ret(result)
      end
    end

    private def load_record_pointers(builder, func)
      [
        builder.load2(LLVM::Type.pointer, func.params[1], "rec_a"),
        builder.load2(LLVM::Type.pointer, func.params[3], "rec_b")
      ]
    end

    private def generate_primitive_type_constants
      generate_type_constant("Int", 8, KIND_PRIMITIVE, nil, @int_equals_fn)
      generate_type_constant("Bool", 1, KIND_PRIMITIVE, nil, @bool_equals_fn)
      generate_type_constant("String", 8, KIND_PRIMITIVE, nil, @string_equals_fn)
      generate_type_constant("Null", 0, KIND_PRIMITIVE, nil, @null_equals_fn)
      generate_type_constant("Type", 8, KIND_TYPE, nil, @type_equals_fn)
    end

    private def generate_type_constant(name, size, kind, fields_ptr = nil, equals_fn_ptr = nil)
      name_global = create_name_string(name)
      fields_value = fields_ptr || LLVM::Type.pointer.null_pointer
      equals_fn_value = equals_fn_ptr || LLVM::Type.pointer.null_pointer
      values = [name_global, LLVM::Int64.from_i(size), LLVM::Int8.from_i(kind), fields_value, equals_fn_value]
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
    def self.generate_record_type_constant(mod, record_name, size_bytes, fields = [], equals_fn = nil)
      new(mod).generate_record_type(record_name, size_bytes, fields, equals_fn)
    end

    def generate_record_type(record_name, size_bytes, fields = [], equals_fn = nil)
      fields_ptr = generate_field_list(record_name, fields)
      generate_type_constant(record_name, size_bytes, KIND_RECORD, fields_ptr, equals_fn)
    end

    def generate_type_for(type)
      generate_type_constant(type.name, type.size_bytes, self.class.type_kind(type))
    end

    # Build a linked list of field entries (last field points to null, each prior field points to the next)
    private def generate_field_list(record_name, fields)
      return LLVM::Type.pointer.null_pointer if fields.empty?

      null_ptr = LLVM::Type.pointer.null_pointer
      fields.each_with_index.reverse_each.reduce(null_ptr) do |rest_ptr, (field, index)|
        generate_field_list_entry(record_name, field, index, rest_ptr)
      end
    end

    private def generate_field_list_entry(record_name, field, index, rest_ptr)
      name_global = create_field_name_string(record_name, field[:name])
      type_ptr = field_type_constant(field)
      values = [name_global, type_ptr, rest_ptr]
      add_field_list_global("Stone.Field.#{record_name}.#{index}.#{field[:name]}", values)
    end

    private def field_type_constant(field)
      field_type = Stone::AST::FieldHelpers.resolve_field_type(field) || Stone::Type::Int
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
      new(mod).generate_type_for(type)
      mod.globals[type_constant_name(type)]
    end

    def self.type_kind(type)
      return KIND_PRIMITIVE if type.primitive?
      return KIND_RECORD if type.record?
      return KIND_UNION if type.union?
      return KIND_FUNCTION if type.function?
      return KIND_TYPE if type == Stone::Type::Type

      KIND_PRIMITIVE
    end

  end
end
