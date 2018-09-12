module Stone

  module AST

    class Rational < Number

      attr_reader :numerator
      attr_reader :denominator

      def initialize(numerator, denominator)
        @source_location = get_source_location(numerator)
        @numerator = numerator.to_s.to_i
        @denominator = denominator.to_s.to_i
        reduce!
      end

      def type
        "Number.Rational"
      end

      def reduce!
        gcd = numerator.gcd(denominator)
        @numerator = numerator / gcd if gcd != 1
        @denominator = denominator / gcd if gcd != 1
      end

      def to_s
        "#{type}(#{numerator}, #{denominator})"
      end


    end

  end

end
