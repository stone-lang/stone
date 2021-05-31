module Stone
  module Builtin

    class Null < Value

      def initialize
        @value = nil
      end

      def type
        "Null"
      end

      def to_s(untyped: false)
        if untyped
          "Null.NULL"
        else
          "#{type}(Null.NULL)"
        end
      end

    end

  end
end
