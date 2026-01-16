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

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        # Union field access: extract type tag at runtime
        return @inner_expression.extract_union_type_tag(builder, mod, scope) if union_field_access?(mod)

        # Default: return compile-time type constant
        context = Stone::TypeContext.new(mod)
        result_type = @inner_expression.type(context)
        Stone::RTTI.type_constant_for(mod, result_type)
      end

      def to_s
        "Type.of(#{@inner_expression})"
      end

      private def union_field_access?(mod)
        @inner_expression.is_a?(PropertyAccess) && @inner_expression.union_field_access?(mod)
      end

    end
  end
end
