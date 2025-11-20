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
        # For now, assume i64 type - we'll need proper type inference later
        global = mod.globals.add(LLVM::Int64, identifier)
        global.linkage = :internal

        llvm_value = value_expression.to_llir(builder, mod)

        if literal_constant?
          initialize_as_constant(global, llvm_value)
        else
          initialize_at_runtime(global, builder, llvm_value)
        end

        nil
      end

      private def initialize_as_constant(global, llvm_value)
        # OPTIMIZE: Use true LLVM constant for literals
        global.initializer = llvm_value
        global.global_constant = true
      end

      private def initialize_at_runtime(global, builder, llvm_value)
        # Runtime initialization for non-constant expressions
        global.initializer = LLVM::Int64.from_i(0)
        # NOTE: NOT setting global_constant = true to allow runtime initialization

        builder.store(llvm_value, global)
      end

      private def literal_constant?
        value_expression.is_a?(Stone::AST::IntegerLiteral)
      end

    end
  end
end
