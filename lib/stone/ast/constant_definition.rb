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
        # Evaluate the expression to get the LLVM constant value
        # For now, we only support constant expressions (literals)
        # TODO: Add support for constant expressions (e.g., 1 + 2)
        llvm_value = value_expression.to_llir(builder, mod)

        # Create a global constant in the module
        # For now, assume i64 type - we'll need proper type inference later
        global = mod.globals.add(LLVM::Int64, identifier)
        global.linkage = :internal
        global.global_constant = true
        global.initializer = llvm_value

        # Constant definitions don't produce a value themselves
        nil
      end

    end
  end
end
