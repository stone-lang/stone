module Stone

  module AST

    class Integer < Number

      def type
        "Number.Integer"
      end

      def normalize!
        case @value
        when /[-+]?0b.*/
          @value = @value.sub("0b", "").to_i(2)
        when /[-+]?0o.*/
          @value = @value.sub("0o", "").to_i(8)
        when /[-+]?0x.*/
          @value = @value.sub("0x", "").to_i(16)
        else
          @value = @value.to_i
        end
      end

    end

  end

end
