module Stone

  module AST

    class LiteralText < Literal

      def type
        "Text"
      end

      def to_s
        "#{type}(\"#{@value}\")"
      end

    end

  end

end
