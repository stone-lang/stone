require "llvm/core"


# Extensions to LLVM::Module to support Stone-specific features
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

  end
end

# Extend LLVM::Module with our extensions
LLVM::Module.include(Stone::LLVMModuleExtensions)
