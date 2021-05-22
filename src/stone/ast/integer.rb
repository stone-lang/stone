module Stone

  module AST

    class Integer < Literal

      attr_reader :value

      def initialize(slice)
        @value = Builtin::Integer.new(slice)
      end

    end

  end

end
