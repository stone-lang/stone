require "stone/ast"


module Stone
  class AST
    class FunctionTypeAnnotation < Stone::AST

      attr_reader :param_types, :return_type

      def initialize(param_types, return_type)
        @param_types = param_types
        @return_type = return_type
        @name = :function_type_annotation
      end

      def to_s
        params = @param_types.map(&:to_s).join(", ")
        return_str = @return_type.is_a?(FunctionTypeAnnotation) ? "(#{@return_type})" : @return_type.to_s
        "(#{params}) -> #{return_str}"
      end

      # Convert to Stone::Type for type checking
      def to_type(registry)
        param_stone_types = @param_types.map { |t| t.to_type(registry) }
        return_stone_type = @return_type.to_type(registry)
        Stone::Type.function(param_types: param_stone_types, return_type: return_stone_type)
      end

    end
  end
end
