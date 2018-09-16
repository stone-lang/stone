module Stone

  module AST

    class Number < Value

      def self.new!(value)
        if value.is_a?(::Integer)
          Integer.new(value)
        elsif value.is_a?(::Rational) && value.denominator == 1
          Integer.new(value.numerator)
        elsif value.is_a?(::Rational)
          Rational.new(value.numerator, value.denominator)
        else
          fail "Don't know how we got a #{value.class} when expecting a Number"
        end
      end

      def type
        "Number"
      end

    end

  end

end


require "stone/ast/integer"
require "stone/ast/rational"
