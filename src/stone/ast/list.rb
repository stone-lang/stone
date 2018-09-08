module Stone

  module AST

    class List < Value

      def initialize(slice_or_string_or_list, type_specifier: Any)
        if slice_or_string_or_list.is_a?(Array)
          @value = slice_or_string_or_list
        else
          super(slice_or_string_or_list)
        end
        @type_specifier = type_specifier
      end

      def type
        "List[#{type_specifier}]"
      end

      def type_specifier
        if @type_specifier == Any && child_types.same?
          child_types.uniq.only
        else
          @type_specifier
        end
      end

      def normalize!
        @value = @value.split(/,\s*/) if @value.is_a?(String)
      end

      def to_s
        "#{type}(#{@value.join(', ')})"
      end

      def children
        @value
      end

      def child_types
        children.map(&:type)
      end

    end

  end

end
