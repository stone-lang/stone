module Stone

  module AST

    class Decimal < Literal

      attr_reader :value

      def initialize(slice)
        @value = Builtin::Decimal.new(slice)
      end

    end

  end

end
