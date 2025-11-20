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
        # Create a global with a dummy constant initializer
        # For now, assume i64 type - we'll need proper type inference later
        global = mod.globals.add(LLVM::Int64, identifier)
        global.initializer = LLVM::Int64.from_i(0)
        global.linkage = :internal
        # NOTE: NOT setting global_constant = true to allow runtime initialization
        # TODO: Add compile-time constant folding to use true constants when possible

        # Evaluate the expression (can be any expression: literal, function call, reference, etc.)
        llvm_value = value_expression.to_llir(builder, mod)

        # Store the computed value to the global
        builder.store(llvm_value, global)

        # Constant definitions don't produce a value themselves
        nil
      end

    end
  end
end
