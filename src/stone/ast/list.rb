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
          map: ->(context, fn) { map("map", context, fn) },
          each: ->(context, fn) { map("each", context, fn) },
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

    private

      def map(name, context, function)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(Function)
        return Error.new("ArityError", "'#{name}' argument 'function' must take 1 argument") unless function.arity.include?(1)
        List.new(@value.map{ |x| function.call(context, [x]) })
      end

    end

  end

end
