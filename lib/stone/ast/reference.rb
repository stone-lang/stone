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
        # Check globals first (constants, variables)
        global = mod.globals[identifier]
        return builder.load(global, identifier) if global

        # Check functions (function names are also references)
        function = mod.functions[identifier]
        return function if function

        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end

      def to_s
        identifier
      end

    end
  end
end
