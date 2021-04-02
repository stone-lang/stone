module Stone

  module AST

    class Text < Value

      def type
        "Text"
      end

      def to_s(untyped = false)
        if untyped
          "\"#{@value}\""
        else
          "#{type}(\"#{@value}\")"
        end
      end

    end

  end

end
