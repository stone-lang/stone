require "stone/ast"


module Stone
  class AST
    class ParameterizedTypeAnnotation < Stone::AST

      attr_reader :base_name, :type_arguments

      def initialize(base_name, type_arguments)
        @base_name = base_name
        @type_arguments = type_arguments
        @name = :parameterized_type_annotation
      end

      def to_s
        "#{base_name}(#{type_arguments.map(&:to_s).join(', ')})"
      end

      # Convert to Stone::Type by looking up the canonical name
      def to_type(registry)
        registry.lookup(to_s)
      end

    end
  end
end
