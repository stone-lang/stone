require "stone/ast/expression"

module Stone
  class AST
    class NullLiteral < Stone::AST::Expression

      def self.parse(_text, _location)
        new
      end

      def initialize
        @name = :null_literal
      end

      def to_llir(_builder, _mod)
        LLVM::Type.ptr.null
      end

      def to_s
        "NULL"
      end

      def type(_context = nil)
        Stone::Type::Null
      end

    end
  end
end
