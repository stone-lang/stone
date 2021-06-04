require "extensions/enumerable"


module Stone

  module Builtin

    class List < Value

      attr_reader :value

      def initialize(list, type_specifier: Any)
        fail "WTF? Expected an Array, got a #{list.class}." unless list.is_a?(Array)
        @value = list
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

      # rubocop:disable Layout/LineLength, Style/Semicolon, Lint/RedundantCopDisableDirective
      PROPERTIES = {
        size: ->(this) { Integer.new(this.value.size) },
        length: ->(this) { Integer.new(this.value.size) },
        empty?: ->(this) { Boolean.new(this.value.size.zero?) },
        first: ->(this) { this.value.first },
        # second: ->(this) { this.value.second },
        head: ->(this) { this.value.first },
        last: ->(this) { this.value.last },
        rest: ->(this) { List.new(this.value.rest) },
        tail: ->(this) { List.new(this.value.tail) },
        nth: ->(this) { Function.new("nth", 1..1, ->(_ctxt, args){ this.value.nth(args.only).value }) },
        includes?: ->(this) { Function.new("includes?", 1..1, ->(_ctxt, args){ Boolean.new(this.value.map(&:value).include?(args.only.value)) }) },
        map: ->(this){ Function.new("map", 1..1, ->(ctxt, args){ this.map("map", ctxt, args.first) }) },
        each: ->(this){ Function.new("each", 1..1, ->(ctxt, args){ this.map("each", ctxt, args.first) }) },
        reduce: ->(this){ Function.new("reduce", 1..1, ->(ctxt, args){ fn = args.first; this.reduce("reduce", ctxt, fn) }) },
        fold: ->(this){ Function.new("fold", 2..2, ->(ctxt, args){ fn = args.first; iv = args.second; this.reduce("fold", ctxt, fn, initial_value: iv) }) },
        foldl: ->(this){ Function.new("foldl", 2..2, ->(ctxt, args){ fn = args.first; iv = args.second; this.reduce("foldl", ctxt, fn, initial_value: iv) }) },
        inject: ->(this){ Function.new("inject", 2..2, ->(ctxt, args){ fn = args.first; iv = args.second; this.reduce("inject", ctxt, fn, initial_value: iv) }) },
        foldr: ->(this){ Function.new("foldr", 2..2, ->(ctxt, args){ fn = args.first; iv = args.second; this.reduce("foldr", ctxt, fn, initial_value: iv, reverse: true) }) },
      }
      # rubocop:enable Layout/LineLength, Style/Semicolon, Lint/RedundantCopDisableDirective

      def to_s
        "#{type}(#{@value.map{ |v| v.to_s(untyped: true) }.join(', ')})"
      end

      override def children
        @value
      end

      def child_types
        children.map(&:type)
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
