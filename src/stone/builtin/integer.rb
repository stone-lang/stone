module Stone

  module Builtin

    class Integer < Number

      def initialize(integer_or_string)
        @value = normalize(integer_or_string)
      end

      def type
        "Number.Integer"
      end

      def normalize(value)
        case value
        when /[-+]?0b.*/
          value.to_s.sub("0b", "").to_i(2)
        when /[-+]?0o.*/
          value.to_s.sub("0o", "").to_i(8)
        when /[-+]?0x.*/
          value.to_s.sub("0x", "").to_i(16)
        else
          value.to_i
        end
      end

    end

  end

end
