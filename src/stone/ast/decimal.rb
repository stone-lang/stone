module Stone

  module AST

    class Decimal < Number

      attr_reader :decimal

      def initialize(decimal)
        @source_location = get_source_location(decimal)
        @decimal = decimal.to_s.sub(/^0+/, "0")
        digits_left_of_decimal_point = @decimal.index(".")
        digits_right_of_decimal_point = @decimal.length - digits_left_of_decimal_point - 1
        numerator = @decimal.tr(".", "")
        denominator = 10**digits_right_of_decimal_point
        @value = Rational(numerator, denominator) # Note that this is Ruby's built-in Rational.
      end

      def type
        "Number.Decimal"
      end

      def to_s
        "#{type}(#{decimal})"
      end

      def normalized!
        Rational.new(value.numerator, value.denominator) # Note that this is Stone's Rational.
      end

    end

  end

end
