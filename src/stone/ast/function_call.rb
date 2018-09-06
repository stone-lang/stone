module Stone

  module AST

    class FunctionCall < Base

      BUILTIN_FUNCTIONS = %i[iff identity min max]

      attr_reader :name
      attr_reader :arguments

      def initialize(name, arguments)
        @source_location = name.line_and_column
        @name = name.to_s.to_sym
        @arguments = arguments
      end

      def to_s
        "#{name}(#{arguments.join(', ')})"
      end

      def evaluate(context)
        evaluated_arguments = arguments.map{ |a| a.evaluate(context) }
        return error?(evaluated_arguments) if error?(evaluated_arguments)
        if context[name].is_a?(Function)
          # TODO: Check arity and types.
          context[name].call(evaluated_arguments)
        elsif builtin_function?(name)
          call_builtin_function(name, evaluated_arguments)
        else
          Error.new("UnknownFunction", name)
        end
      end

    private

      def builtin_function?(name)
        name = :iff if name == :if
        BUILTIN_FUNCTIONS.include?(name)
      end

      def call_builtin_function(name, evaluated_arguments)
        name = :iff if name == :if
        __send__(name, evaluated_arguments)
      end

      def iff(args)
        return Error.new("ArityError", "expecting 2 or 3 arguments, got #{args.size}") unless [2, 3].include?(args.size)
        condition, consequent, alternative = args
        return Error.new("TypeError", "`if` condition must be a Boolean") unless condition.is_a?(Boolean)
        return Error.new("TypeError", "`if` consequent (`then`) must be a block") unless consequent.is_a?(Block)
        return Error.new("TypeError", "`if` alternative (`else`) must be a block") unless alternative.is_a?(Block) || alternative.nil?
        if condition.value
          consequent.call
        elsif alternative
          alternative.call
        end
      end

      def identity(args)
        return Error.new("ArityError", "expecting 1 argument, got #{args.size}") unless args.size == 1
        args.first
      end

      def min(args)
        # TODO: Check types.
        Integer.new(args.map(&:value).min)
      end

      def max(args)
        # TODO: Check types.
        Integer.new(args.map(&:value).max)
      end

    end

  end

end
