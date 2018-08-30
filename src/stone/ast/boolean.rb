module Stone

  module AST

    class Boolean < Value

      def type
        "Boolean"
      end

      def normalize!
        @value = ["TRUE", "true", true].include?(@value)
      end

      def to_s
        "#{type}(Boolean.#{@value.to_s.upcase})"
      end

    end

  end

end
