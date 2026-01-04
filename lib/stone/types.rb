require "stone/type/base"
require "stone/type/Bool"
require "stone/type/Int"
require "stone/type/String"
require "stone/type/type"
require "stone/type"
require "stone/type_registry"

# Set up property type mappings for class-based types (backward compat)
Stone::Type::Int::PROPERTY_TYPES["positive?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["negative?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["zero?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::Bool::PROPERTY_TYPES["not"] = Stone::Type::Bool
Stone::Type::Bool::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::String::PROPERTY_TYPES["byte_count"] = Stone::Type::Int
Stone::Type::String::PROPERTY_TYPES["empty?"] = Stone::Type::Bool
Stone::Type::String::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::Type::PROPERTY_TYPES["as_String"] = Stone::Type::String


# Bootstrap the TypeRegistry with primitive types
module Stone
  module Types
  module_function

    def bootstrap_registry!
      types = create_primitive_types
      register_all_types(types)
      setup_property_types(types)
      Stone::TypeRegistry.instance
    end

    def create_primitive_types
      {
        int: Stone::TypeInstance.primitive(name: "Int", llvm_type: LLVM::Int64.type),
        bool: Stone::TypeInstance.primitive(name: "Bool", llvm_type: LLVM::Int1.type),
        string: Stone::TypeInstance.primitive(name: "String", llvm_type: LLVM::Int64.type),
        type: Stone::TypeInstance.primitive(name: "Type", llvm_type: LLVM::Int64.type)
      }
    end

    def register_all_types(types)
      registry = Stone::TypeRegistry.instance
      types.each_value { |type| registry.register(type) }
    end

    def setup_property_types(types)
      setup_int_properties(types)
      setup_bool_properties(types)
      setup_string_properties(types)
      types[:type].property_types["as_String"] = types[:string]
    end

    def setup_int_properties(types)
      types[:int].property_types.merge!(
        "positive?" => types[:bool], "negative?" => types[:bool],
        "zero?" => types[:bool], "as_String" => types[:string]
      )
    end

    def setup_bool_properties(types)
      types[:bool].property_types.merge!("not" => types[:bool], "as_String" => types[:string])
    end

    def setup_string_properties(types)
      types[:string].property_types.merge!(
        "byte_count" => types[:int], "empty?" => types[:bool], "as_String" => types[:string]
      )
    end
  end
end

# Bootstrap on load
Stone::Types.bootstrap_registry!
