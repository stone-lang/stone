require "stone/ast/expression"


module Stone
  class AST
    class IntegerLiteral < Stone::AST::Expression

      BASES = {
        "0b" => 2,
        "0o" => 8,
        "0x" => 16
      }.freeze

      # TODO: This looks like a good place to set a good example: refactor into a Method Object.
      def self.parse(text, location)
        sign = text.start_with?("-") ? -1 : 1
        unsigned_text = text.sub(/^[+-]/, "")
        base = BASES.fetch(unsigned_text[0..1], 10)
        digits = base == 10 ? unsigned_text : unsigned_text[2..]
        value = sign * Integer(digits, base)
        fail Stone::Error::Overflow.new(location:, literal: text) unless in_range?(value)
        new(value)
      end

      def self.in_range?(value)
        value >= Stone::Type::Int.min && value <= Stone::Type::Int.max
      end

      attr_reader :value

      def initialize(value)
        @value = value
        @name = :integer_literal
      end

      def to_llir(_builder, _mod, _scope = Stone::Scope.top_level)
        LLVM::Int64.from_i(@value)
      end

      def type(_context = nil)
        Stone::Type::Int
      end

    end
  end
end
