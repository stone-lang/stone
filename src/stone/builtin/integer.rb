require "stone/builtin/number"


module Stone

  module Builtin

    class Integer < Number

      def initialize(value)
        @value = value
        normalize!
      end

      def type
        "Number.Integer"
      end

      def normalize!
        case @value
        when /[-+]?0b.*/
          @value = @value.to_s.sub("0b", "").to_i(2)
        when /[-+]?0o.*/
          @value = @value.to_s.sub("0o", "").to_i(8)
        when /[-+]?0x.*/
          @value = @value.to_s.sub("0x", "").to_i(16)
        else
          @value = @value.to_i
        end
      end

    end

  end

end
