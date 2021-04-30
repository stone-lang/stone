module Stone

  module AST

    class Boolean < Value

      def type
        "Boolean"
      end

      def normalize!
        @value = ["TRUE", "true", true].include?(@value)
      end

      def to_s(untyped: false)
        if untyped
          "Boolean.#{@value.to_s.upcase}"
        else
          "#{type}(Boolean.#{@value.to_s.upcase})"
        end
      end

    end

  end

end
