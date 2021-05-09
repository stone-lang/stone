require "stone/builtin/value"


module Stone

  module Builtin

    class Boolean < Value

      def initialize(true_or_false)
        @value = true_or_false
      end

      def type
        "Boolean"
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
