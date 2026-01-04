require "stone/ast/expression"
require "stone/type_context"


module Stone
  class AST
    class TypeOfExpression < Stone::AST::Expression

      attr_reader :inner_expression

      def initialize(inner_expression)
        @inner_expression = inner_expression
        @name = :type_of_expression
      end

      def type(_context = nil)
        # Type.of() returns the Type metatype
        Stone::TypeRegistry.instance.type
      end

      def to_llir(_builder, mod)
        # At compile time, determine the type of the inner expression
        # For now, create a TypeContext from the module
        context = Stone::TypeContext.new(mod)
        result_type = @inner_expression.type(context)

        # Return a reference to the type object
        # For now, we'll represent types as integers (a simple encoding)
        # This is a placeholder until we have proper type objects at runtime
        type_id = type_to_id(result_type)
        LLVM::Int64.from_i(type_id)
      end

      def to_s
        "Type.of(#{@inner_expression})"
      end

      private def type_to_id(type)
        registry = Stone::TypeRegistry.instance
        case type
        when registry.int then 1
        when registry.bool then 2
        when registry.string then 3
        when registry.type then 4
        else 0 # Unknown
        end
      end

    end
  end
end
