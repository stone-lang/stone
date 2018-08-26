module Stone

  module AST

    class LiteralInteger < Literal

      def type
        "Number.Integer"
      end

      def normalize!
        @value.delete_prefix!("+")
      end

    end

  end

end
