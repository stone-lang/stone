module Stone

  module AST

    class Rational < Literal

      attr_reader :value

      def initialize(numerator_slice, denominator_slice)
        @value = Builtin::Rational.new(numerator_slice, denominator_slice)
      end

    end

  end

end
