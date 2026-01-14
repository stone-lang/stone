require "stone/ast/expression"
require "stone/type_context"
require "stone/rtti"


module Stone
  class AST
    class TypeOfExpression < Stone::AST::Expression

      attr_reader :inner_expression

      def initialize(inner_expression)
        @inner_expression = inner_expression
        @name = :type_of_expression
      end

      def type(_context = nil)
        Stone::Type::Type
      end

      def to_llir(_builder, mod, _scope = Stone::Scope.top_level)
        context = Stone::TypeContext.new(mod)
        result_type = @inner_expression.type(context)

        # Return pointer to the type constant
        Stone::RTTI.type_constant_for(mod, result_type)
      end

      def to_s
        "Type.of(#{@inner_expression})"
      end

    end
  end
end
