require "stone/ast"


module Stone
  class AST
    class TypeAnnotation < Stone::AST

      attr_reader :type_name

      def initialize(type_name)
        @type_name = type_name
        @name = :type_annotation
      end

      def to_s
        type_name
      end

    end
  end
end
