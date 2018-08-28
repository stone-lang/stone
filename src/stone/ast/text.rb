module Stone

  module AST

    class Text < Value

      def type
        "Text"
      end

      def to_s
        "#{type}(\"#{@value}\")"
      end

    end

  end

end
