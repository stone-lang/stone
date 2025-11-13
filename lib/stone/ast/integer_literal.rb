require "stone/ast"


module Stone
  class AST
    class IntegerLiteral < Stone::AST

      attr_reader :value

      def initialize(value)
        @value = value
        @name = :integer_literal
      end

      def to_llir(_builder)
        LLVM::Int64.from_i(@value)
      end

    end
  end
end
