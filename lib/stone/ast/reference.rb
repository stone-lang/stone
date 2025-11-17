require "stone/ast"


module Stone
  class AST
    class Reference < Stone::AST

      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
        @name = :reference
      end

      def to_llir(builder, mod)
        global = mod.globals[identifier]

        fail Stone::ReferenceError, "undefined constant or variable: #{identifier}" unless global

        builder.load(global, identifier)
      end

      def to_s
        identifier
      end

    end
  end
end
