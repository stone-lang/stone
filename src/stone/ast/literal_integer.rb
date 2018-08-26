module Stone

  module AST

    class LiteralInteger < Literal

      def type
        "Number.Integer"
      end

      def normalize!
        @value.delete_prefix!("+")
        @value.gsub!(/^0+/, "")
        @value.gsub!(/^-0+/, "-")
        @value = "0" if @value.match?(/^-?$/)
      end

    end

  end

end
