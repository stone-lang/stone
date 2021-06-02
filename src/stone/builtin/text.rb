module Stone

  module Builtin

    class Text < Value

      def type
        "Text"
      end

      PROPERTIES = {
        length: ->(this) { Integer.new(this.value.length) },
        chomp: ->(this) { Text.new(this.value.chomp) },
        empty?: ->(this) { Boolean.new(this.value.empty?) },
        __hash__: ->(this) { Integer.new(this.value.hash) },
        strip: ->(this) { Text.new(this.value.strip) },
        reversed: ->(this) { Text.new(this.value.reverse) },
        lower_cased: ->(this) { Text.new(this.value.downcase) },
        upper_cased: ->(this) { Text.new(this.value.upcase) },
      }

      def to_s(untyped: false)
        if untyped
          "\"#{@value}\""
        else
          "#{type}(\"#{@value}\")"
        end
      end

    end

  end

end
