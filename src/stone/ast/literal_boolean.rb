module Stone

  module AST

    class LiteralBoolean < Literal

      def type
        "Boolean"
      end

      def normalize!
        @value = @value == "TRUE"
      end

      def to_s
        "#{type}(Boolean.#{@value.to_s.upcase})"
      end

    end

  end

end
