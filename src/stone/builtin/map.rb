require "extensions/enumerable"


module Stone

  module Builtin

    class Map < Value

      attr_reader :value

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

      def call(_parent_context, arguments)
        key = arguments.first
        @value.select { |k, _v| k.value == key.value }.values.first
      end

      def arity
        1..1 # If we treat a Map as a function, it'll take 1 argument (a key).
      end

      # rubocop:disable Layout/LineLength, Style/Semicolon, Lint/RedundantCopDisableDirective
      PROPERTIES = {
        keys: ->(this){ List.new(this.value.keys) },
        values: ->(this){ List.new(this.value.values) },
        size: ->(this){ Integer.new(this.value.size) },
        length: ->(this){ Integer.new(this.value.size) },
        empty?: ->(this){ Boolean.new(this.value.empty?) },
        includes?: ->(this) { Function.new("includes?", 1..1, ->(_ctxt, args){ Boolean.new(this.value.map{ |k, v| [k.value, v.value] }.to_h[args.first.first.value] == args.first.second.value) }) },
        has_key?: ->(this) { Function.new("has_key?", 1..1, ->(_ctxt, args){ Boolean.new(this.value.keys.map(&:value).include?(args.only.value)) }) },
        has_value?: ->(this) { Function.new("has_value?", 1..1, ->(_ctxt, args){ Boolean.new(this.value.values.map(&:value).include?(args.only.value)) }) },
        get: ->(this){ Function.new("get", 1..1, ->(_ctxt, args){ this.value.select { |k, _v| k.value == args.first.value }.values.first }) },
        # map: ->(this){ Function.new("map", 1..1, ->(ctxt, args){ this.map("map", ctxt, args.first) }) },
        # each: ->(this){ Function.new("each", 1..1, ->(ctxt, args){ this.map("each", ctxt, args.first) }) },
      }
      # rubocop:enable Layout/LineLength, Style/Semicolon, Lint/RedundantCopDisableDirective

      def to_s
        "#{type}(#{@value.map{ |k, v| "Pair(#{k.to_s(untyped: true)}, #{v.to_s(untyped: true)})" }.join(', ')})"
      end

      override def children
        @value
      end

      def child_types
        children.map{ |k, v| [k.type, v.type] }.uniq
      end

      def map(name, context, function)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(AST::Function)
        return Error.new("ArityError", "'#{name}' argument 'function' must take 1 argument") unless function.arity.include?(1)
        List.new(@value.map{ |x| function.call(context, [x]) })
      end

      def reduce(name, context, function, initial_value: nil, reverse: false)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(AST::Function)
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
