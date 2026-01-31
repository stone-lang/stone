require "llvm/core"
require "stone/type"
require "stone/type_registry"

# LLVM type alias for convenience
I64 = LLVM::Int64.type


# Bootstrap the TypeRegistry with primitive types
module Stone
  module Types
  module_function

    INT_MIN = -(2**63)   # -9_223_372_036_854_775_808
    INT_MAX = 2**63 - 1  # +9_223_372_036_854_775_807

    def bootstrap_registry!
      types = create_types
      register_all_types(types)
      setup_property_types(types)
      aliases = create_type_aliases(types)
      register_all_types(aliases)
      setup_type_constants(types.merge(aliases))
      Stone::TypeRegistry.instance
    end

    def create_types
      primitives = create_primitive_types
      records = create_record_types(primitives)
      primitives.merge(records)
    end

    def create_primitive_types
      {
        int: Stone::Type.primitive(name: "Int", llvm_type: LLVM::Int64.type, min: INT_MIN, max: INT_MAX),
        bool: Stone::Type.primitive(name: "Bool", llvm_type: LLVM::Int1.type),
        string: Stone::Type.primitive(name: "String", llvm_type: LLVM::Int64.type),
        type: Stone::Type.primitive(name: "Type", llvm_type: LLVM::Type.pointer),
        null: Stone::Type.primitive(name: "Null", llvm_type: LLVM::Type.ptr),
        record: Stone::Type.primitive(name: "Record", llvm_type: LLVM::Type.pointer, generic_for: :record),
        function: Stone::Type.primitive(name: "Function", llvm_type: LLVM::Type.pointer, generic_for: :function)
      }
    end

    def create_record_types(_primitives)
      # FieldList is a linked-list record type for runtime field metadata.
      # TODO: Replace with List(Record::Field) once generics are available.
      {
        field_list: Stone::Type.record(name: "FieldList", fields: [], llvm_type: LLVM::Type.pointer)
      }
    end

    def register_all_types(types)
      registry = Stone::TypeRegistry.instance
      types.each_value { |type| registry.register(type) }
    end

    def create_type_aliases(types)
      primitive = Stone::Type.union(
        alternatives: [types[:null], types[:bool], types[:int], types[:string]],
        name: "Primitive"
      )
      # TODO: Add Collection, Process, Error to Any when available
      any = Stone::Type.union(
        alternatives: [primitive, types[:record], types[:function], types[:type]],
        name: "Any"
      )
      {primitive: primitive, any: any}
    end

    def setup_property_types(types)
      setup_int_properties(types)
      setup_bool_properties(types)
      setup_string_properties(types)
      setup_type_properties(types)
      setup_field_list_properties(types)
    end

    def setup_type_properties(types)
      types[:type].property_types.merge!(
        "as_String" => types[:string],
        "record?" => types[:bool],
        "primitive?" => types[:bool],
        "kind" => types[:int],
        "size" => types[:int],
        "fields" => types[:field_list]
      )
    end

    def setup_field_list_properties(types)
      types[:field_list].property_types.merge!(
        "first" => types[:field_list],  # .first returns the FieldList itself (list-like access)
        "name" => types[:string],       # Field name
        "type" => types[:type],         # Type of the field
        "rest" => types[:field_list]    # Next FieldList or NULL
      )
    end

    def setup_int_properties(types)
      types[:int].property_types.merge!("positive?" => types[:bool], "negative?" => types[:bool],
                                        "zero?" => types[:bool], "as_String" => types[:string])
    end

    def setup_bool_properties(types)
      types[:bool].property_types.merge!("not" => types[:bool], "as_String" => types[:string])
    end

    def setup_string_properties(types)
      types[:string].property_types.merge!("byte_count" => types[:int], "empty?" => types[:bool],
                                           "as_String" => types[:string])
    end

    # Constant names that would collide with subclass names
    GENERIC_CONSTANT_NAMES = {
      "Record" => :GENERIC_RECORD,
      "Function" => :GENERIC_FUNCTION,
      "Primitive" => :GENERIC_PRIMITIVE
    }.freeze

    def setup_type_constants(types)
      # Define type constants on Stone::Type for convenient access
      # Only define if not already defined (avoids warnings during test resets)
      types.each_value do |type|
        constant_name = GENERIC_CONSTANT_NAMES[type.name] || type.name.to_sym
        define_type_constant(constant_name, type)
      end
      define_type_constant(:Registry, Stone::TypeRegistry.instance)
    end

    private def define_type_constant(name, value)
      Stone::Type.const_set(name, value) unless Stone::Type.const_defined?(name, false)
    end
  end
end

# Bootstrap on load
Stone::Types.bootstrap_registry!
