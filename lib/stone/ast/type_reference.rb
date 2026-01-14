require "stone/ast/expression"
require "stone/rtti"


module Stone
  class AST
    class TypeReference < Stone::AST::Expression

      def initialize
        @name = :type_reference
      end

      def type(_context = nil)
        Stone::Type::Type
      end

      def to_llir(_builder, mod, _scope = Stone::Scope.top_level)
        # Return pointer to the Type type constant
        Stone::RTTI.type_constant_for(mod, Stone::Type::Type)
      end

      def to_s
        "Type"
      end

    end
  end
end
