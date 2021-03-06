require "extensions/enumerable"


module Stone

  module Builtin

    class Class < Function

      attr_reader :name
      attr_reader :default_constructor

      def initialize(name, _arity, default_constructor, properties, methods)
        @name = name
        @arity = properties.size
        @default_constructor = default_constructor
        @properties = properties
        @methods = methods
      end

      def klass
        "Class"
      end

      def type
        "Class(\"#{name}\")"
      end

      def call(parent_context, arguments)
        proc.call(parent_context, arguments)
      end

      # FIXME: Move all these into PROPERTIES.
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

      # FIXME: Move all these into PROPERTIES.
      def methods # rubocop:disable Metrics/AbcSize
        @methods ||= {
          includes?: ->(_, element) { Boolean.new(@value.map(&:value).include?(element.value)) },
          map: ->(context, fn) { map("map", context, fn) },
          each: ->(context, fn) { map("each", context, fn) },
          reduce: ->(context, fn) { reduce("reduce", context, fn) },
          fold: ->(context, fn, iv) { reduce("fold", context, fn, initial_value: iv) },
          foldl: ->(context, fn, iv) { reduce("foldl", context, fn, initial_value: iv) },
          inject: ->(context, fn, iv) { reduce("inject", context, fn, initial_value: iv) },
          foldr: ->(context, fn, iv) { reduce("foldr", context, fn, initial_value: iv, reverse: true) },
        }
      end

      def to_s
        "#{type}(#{@value.map{ |v| v.to_s(untyped: true) }.join(', ')})"
      end

      override def children
        @value
      end

      def child_types
        children.map(&:type)
      end

      private def map(name, context, function)
        return Error.new("TypeError", "'#{name}' argument 'function' must have type Function[Any](Any)") unless function.is_a?(AST::Function)
        return Error.new("ArityError", "'#{name}' argument 'function' must take 1 argument") unless function.arity.include?(1)
        List.new(@value.map{ |x| function.call(context, [x]) })
      end

      private def reduce(name, context, function, initial_value: nil, reverse: false)
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
