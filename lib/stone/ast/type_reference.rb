require "stone/ast/expression"


module Stone
  class AST
    class TypeReference < Stone::AST::Expression

      def initialize
        @name = :type_reference
      end

      def type(_context = nil)
        # Type itself has the Type metatype
        Stone::TypeRegistry.instance.type
      end

      def to_llir(_builder, _mod)
        # Type reference returns the Type ID
        LLVM::Int64.from_i(4) # Type's ID
      end

      def to_s
        "Type"
      end

    end
  end
end
