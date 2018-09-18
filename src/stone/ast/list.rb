require "extensions/enumerable"


module Stone

  module AST

    class List < Object

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
          @type_specifier.type
        end
      end

      def normalize!
        @value = @value.split(/,\s*/) if @value.is_a?(String)
      end

      def properties
        @properties ||= {
          size: Integer.new(@value.size),
          length: Integer.new(@value.size),
          empty?: Boolean.new(@value.size.zero?),
          first: @value.first,
          head: @value.first,
          last: @value.last,
          rest: List.new(@value.rest),
          tail: List.new(@value.tail),
        }
      end

      def methods
        @methods ||= {
          includes?: ->(_, element) { Boolean.new(@value.map(&:value).include?(element.value)) },
          map: ->(context, fn) { List.new(@value.map{ |x| fn.call(context, [x]) }) },
          each: ->(context, fn) { List.new(@value.map{ |x| fn.call(context, [x]) }) },
        }
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
