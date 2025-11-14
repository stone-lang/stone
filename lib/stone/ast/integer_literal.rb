require "stone/ast"


module Stone
  class AST
    class IntegerLiteral < Stone::AST

      # i64 range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
      MIN = -(2**63)
      MAX = 2**63 - 1

      def self.in_range?(value)
        value >= MIN && value <= MAX
      end

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
