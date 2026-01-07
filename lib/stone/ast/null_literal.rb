require "stone/ast/expression"

module Stone
  class AST
    class NullLiteral < Stone::AST::Expression

      # NULL is represented as 0 at runtime (null pointer convention)
      LLVM_VALUE = 0

      def self.parse(_text, _location)
        new
      end

      def initialize
        @name = :null_literal
      end

      def to_llir(_builder, _mod)
        LLVM::Int64.from_i(LLVM_VALUE)
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
