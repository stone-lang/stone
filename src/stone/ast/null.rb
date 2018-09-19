module Stone

  module AST

    class Null < Value

      def type
        "Null"
      end

      def normalize!
        @value = nil
      end

      def to_s
        "#{type}(Null.NULL)"
      end

    end

  end

end
