require "llvm/core"


# Extensions to LLVM::Module to support Stone-specific features
#
# NOTE: Many of these registries are now duplicated in Stone::Scope for lexical scoping:
# - string_constants: types also stored via scope.declare_type(name, type: Stone::Type::String)
# - record_instances: types also stored via scope.declare_type(name, type: record_type)
# - function_aliases: values also stored via scope.define(name, value: function)
#
# The module registries remain necessary for:
# - Computed properties (Int@abs) which are global, not lexically scoped
# - Type inference via the `type` method (which doesn't have access to scope)
# - Property access lookups that need the actual AST node (not just the type)
#
# Future work: migrate fully to scope by updating `type` method signatures to accept scope.
module Stone
  module LLVMModuleExtensions

    # Get the function aliases hash, creating it if it doesn't exist
    def function_aliases
      @function_aliases ||= {}
    end

    # Register a function alias (e.g., for lambdas assigned to constants)
    def register_function_alias(name, function)
      function_aliases[name] = function
    end

    # Look up a function by name, checking aliases if not found in the module's function table
    def lookup_function(name)
      functions[name] || function_aliases[name]
    end

    # Get the current lambda parameter storage context
    def lambda_param_storage
      @lambda_param_storage
    end

    # Set the lambda parameter storage context (used during lambda compilation)
    def lambda_param_storage=(storage)
      @lambda_param_storage = storage
    end

    # Track which constants are strings (for type checking during returns)
    def string_constants
      @string_constants ||= {}
    end

    def register_string_constant(name, string_literal)
      string_constants[name] = string_literal
    end

    def string_constant?(name)
      string_constants.key?(name)
    end

    # TODO: Type system refactor needed.
    # This ad-hoc tracking of record types and instances should be replaced
    # with a proper Type class hierarchy where:
    # - All types (Bool, Int, String, Records) are Type instances
    # - Types are global constants accessible at runtime
    # - Types have vtables for properties and polymorphic operations
    # - typeof() can get the type of any value
    # - User-defined types work the same as built-in types

    # Track record type definitions
    def record_types
      @record_types ||= {}
    end

    def register_record_type(name, record_definition)
      record_types[name] = record_definition
    end

    def record_type?(name)
      record_types.key?(name)
    end

    # Track which variables hold record instances (maps variable name -> record type name)
    def record_instances
      @record_instances ||= {}
    end

    def register_record_instance(variable_name, record_type_name)
      record_instances[variable_name] = record_type_name
    end

    def record_instance?(variable_name)
      record_instances.key?(variable_name)
    end

    def record_instance_type(variable_name)
      record_instances[variable_name]
    end

    def generic_types
      @generic_types ||= {}
    end

    def register_generic_type(name, lambda_node)
      generic_types[name] = Stone::Type::Generic.new(name:, template: lambda_node)
    end

    def generic_type?(name)
      generic_types.key?(name)
    end

  end
end

# Extend LLVM::Module with our extensions
LLVM::Module.include(Stone::LLVMModuleExtensions)
