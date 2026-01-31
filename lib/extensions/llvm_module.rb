require "llvm/core"


# Compilation-scoped registries for LLVM::Module.
#
# These track LLVM-level artifacts during a single compilation pass.
# Type lookups have been migrated to Stone::Type::Registry; these registries
# hold LLVM objects (functions, allocations) or compilation-scoped AST data
# that cannot live in the global Registry.
#
# Remaining registries:
# - function_aliases: LLVM::Function objects for operators, computed properties, lambdas
# - lambda_param_storage: temporary LLVM stack allocations during lambda compilation
# - string_constants: maps constant names to StringLiteral AST nodes for type inference
# - record_instances: maps variable names to record type names for property access
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

  end
end

# Extend LLVM::Module with our extensions
LLVM::Module.include(Stone::LLVMModuleExtensions)
