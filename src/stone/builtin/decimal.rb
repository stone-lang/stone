require "extensions/string"
require "extensions/integer"


module Stone

  module Builtin

    class Decimal < Number

      attr_reader :numerator, :denominator
      attr_reader :significant_digits
      attr_reader :whole, :fraction, :exponent

      def initialize(decimal)
        @source_location = nil # WAS: get_source_location(decimal)
        whole, fraction, exponent = decimal.to_s.split(/[.eE\u23E8]/)
        compute_components!(whole, fraction, exponent)
        digits = "#{whole}#{fraction}"
        @significant_digits = digits.length - (digits.start_with?(/[+-]/) ? 1 : 0)
        @numerator = digits.to_i
        @denominator = 10**(fraction.length - exponent.to_i)
        @value = Rational(@numerator, @denominator) # Note that this is Ruby's built-in Rational.
      end

      def type
        "Number.Decimal"
      end

      def to_s
        "#{type}(#{sign}#{whole.abs}.#{fraction}E#{exponent.sign}#{exponent.abs})"
      end

      def normalized!
        Stone::Builtin::Rational.new(numerator, denominator).normalized! # Note that this is Stone's Rational.
      end

      def sign
        numerator.sign
      end

      def compute_components!(whole, fraction, exponent)
        digits = "#{whole}#{fraction}"
        @whole = digits.first(digits.start_with?(/[+-]/) ? 2 : 1).to_i
        @fraction = digits.rest(digits.start_with?(/[+-]/) ? 2 : 1)
        @exponent = exponent.to_i + whole.length - (digits.start_with?(/[+-]/) ? 2 : 1)
      end

    end

  end

end
