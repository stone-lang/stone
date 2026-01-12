require "stone/ast"


module Stone
  class AST
    class TypeDeclaration < Stone::AST

      attr_reader :identifier, :type_annotation, :location

      def initialize(identifier, type_annotation, location: nil)
        @identifier = identifier
        @type_annotation = type_annotation
        @location = location
        @name = :type_declaration
      end

      def to_s
        "#{identifier} :: #{type_annotation}"
      end

      # Type declarations don't produce a value, so they have no type
      def type(_context = nil)
        nil
      end

    end
  end
end
