module Stone

  module Builtin

    class Number < Value

      def self.new!(value) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if value.is_a?(::Integer)
          Builtin::Integer.new(value)
        elsif value.is_a?(::Rational) && value.denominator == 1
          Builtin::Integer.new(value.numerator)
        elsif value.is_a?(::Rational) && (value.denominator % 10).zero?
          Builtin::Decimal.new((value.numerator.to_f / value.denominator).to_s)
        elsif value.is_a?(::Rational)
          Builtin::Rational.new(value.numerator, value.denominator)
        else
          fail "Don't know how we got a #{value.class} when expecting a Number"
        end
      end

      abstract :type

    end

  end

end


require "stone/builtin/integer"
require "stone/builtin/decimal"
require "stone/builtin/rational"
