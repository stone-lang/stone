require "stone/ast"


module Stone
  class AST
    class TypeDeclaration < Stone::AST

      attr_reader :identifier, :type_annotation

      def initialize(identifier, type_annotation)
        @identifier = identifier
        @type_annotation = type_annotation
        @name = :type_declaration
      end

      def to_s
        "#{identifier} :: #{type_annotation}"
      end

    end
  end
end
