module Stone

  module AST

    class Text < Literal

      attr_reader :value

      def initialize(slice)
        @value = Builtin::Text.new(slice)
      end

    end

  end

end
