module Stone

  module AST

    class Null < Value

      def type
        "Null"
      end

      def normalize!
        @value = nil
      end

      def to_s(untyped = false)
        if untyped
          "Null.NULL"
        else
          "#{type}(Null.NULL)"
        end
      end

    end

  end

end
