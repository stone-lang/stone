require "extensions/enumerable"


module Stone

  module AST

    class Map < Object

      def initialize(hashmap, type_specifier: [Any, Any])
        # TODO: Check that they're all pairs.
        @type_specifier = type_specifier
        super(hashmap)
        @value = hashmap.map{ |pair| [pair.first, pair.second] }.to_h
      end

      def type
        "Map[#{type_specifier}]"
      end

      def type_specifier
        if @type_specifier == [Any, Any] && child_types
          return "Any, Any" if child_types.empty?
          child_types.first.join(", ") # TODO: Need to find the most-specific common ancestor of key and value type, not just the first key/value types.
        else
          @type_specifier
        end
      end

      def properties
        @properties ||= {
          keys: List.new(@value.keys),
          values: List.new(@value.values),
          size: Integer.new(@value.size),
          length: Integer.new(@value.size),
          empty?: Boolean.new(@value.size.zero?),
        }
      end

      def methods # rubocop:disable Metrics/AbcSize
        @methods ||= {
          includes?: ->(_, element) { Boolean.new(@value.map{ |k,v| [k.value, v.value] }.to_h[element.first.value] == element.second.value) },
          has_key?: ->(_, key) { Boolean.new(@value.keys.map(&:value).include?(key.value)) },
          has_value?: ->(_, value) { Boolean.new(@value.values.map(&:value).include?(value.value)) },
          get: ->(context, key) { @value.select { |k,v| k.value == key.value }.values.first },
          map: ->(context, fn) { map("map", context, fn) },
          each: ->(context, fn) { map("each", context, fn) },
        }
      end

      def to_s
        "#{type}(#{@value.map{ |k, v| "Pair(#{k.to_s(untyped: true)}, #{v.to_s(untyped: true)})" }.join(', ')})"
      end

      def children
        @value
      end

      def child_types
        children.map{ |k,v| [k.type, v.type] }.uniq
      end

      private def map(name, context, function)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(Function)
        return Error.new("ArityError", "'#{name}' argument 'function' must take 1 argument") unless function.arity.include?(1)
        List.new(@value.map{ |x| function.call(context, [x]) })
      end

      private def reduce(name, context, function, initial_value: nil, reverse: false)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(Function)
        return Error.new("ArityError", "'#{name}' argument 'function' must take 2 arguments") unless function.arity.include?(2)
        reverse_or_not = reverse ? :reverse : :itself
        list = value.__send__(reverse_or_not)
        if initial_value
          list.reduce(initial_value){ |x, y| function.call(context, [x, y].__send__(reverse_or_not)) }
        else
          list.reduce{ |x, y| function.call(context, [x, y].__send__(reverse_or_not)) }
        end
      end

    end

  end

end
