module Stone

  module AST

    class Rational < Number

      attr_reader :numerator
      attr_reader :denominator

      def initialize(numerator, denominator = 1)
        @source_location = get_source_location(numerator)
        if numerator.is_a?(Rational)
          @numerator = numerator.numerator
          @denominator = numerator.denominator
        else
          @numerator = numerator.to_s.to_i
          @denominator = denominator.to_s.to_i
        end
        reduce!
      end

      def type
        "Number.Rational"
      end

      def reduce!
        @numerator = -@numerator if @denominator.negative?
        @denominator = -@denominator if @denominator.negative?
        gcd = numerator.gcd(denominator)
        return if gcd == 1
        @numerator = numerator / gcd
        @denominator = denominator / gcd
      end

      def to_s
        "#{type}(#{numerator}, #{denominator})"
      end

      def normalized!
        denominator == 1 ? Integer.new(numerator) : self
      end

      # Note that we're returning a native Ruby `Rational` here.
      def value
        Rational(numerator, denominator)
      end

    end

  end

end
