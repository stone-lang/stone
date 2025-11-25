require "stone/ast"


module Stone
  class AST
    class ConstantDefinition < Stone::AST

      attr_reader :identifier, :value_expression

      def initialize(identifier, value_expression)
        @identifier = identifier
        @value_expression = value_expression
        @name = :constant_definition
      end

      def to_llir(builder, mod)
        llvm_value = value_expression.to_llir(builder, mod)

        return register_function_alias(mod, llvm_value) if llvm_value.is_a?(LLVM::Function)

        global = mod.globals.add(llvm_value.type, identifier)
        global.linkage = :internal

        if literal_constant?
          initialize_as_constant(global, llvm_value)
        else
          initialize_at_runtime(global, builder, llvm_value)
        end

        nil
      end

      # Register a function (lambda) as an alias so it can be called by the constant name
      private def register_function_alias(mod, function)
        mod.register_function_alias(identifier, function)
        nil
      end

      # Use true LLVM constants, when we can
      private def initialize_as_constant(global, llvm_value)
        global.global_constant = true
        global.initializer = llvm_value
      end

      # Runtime initialization for non-constant expressions
      private def initialize_at_runtime(global, builder, llvm_value)
        global.global_constant = false # Allow runtime update
        global.initializer = LLVM::Int64.from_i(0)
        builder.store(llvm_value, global)
      end

      private def literal_constant?
        value_expression.is_a?(Stone::AST::IntegerLiteral)
      end

    end
  end
end
