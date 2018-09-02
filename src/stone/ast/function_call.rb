module Stone

  module AST

    class FunctionCall < Base

      BUILTIN_FUNCTIONS = %i[identity min max]

      attr_reader :name
      attr_reader :arguments

      def initialize(name, arguments)
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
          context[name].call(evaluated_arguments)
        elsif builtin_function?(name)
          __send__(name, evaluated_arguments)
        else
          Error.new("UnknownFunction", name)
        end
      end

    private

      def builtin_function?(name)
        BUILTIN_FUNCTIONS.include?(name)
      end

      def identity(args)
        return Error.new("ArityError", "expecting 1 argument, got #{args.size}") unless args.size == 1
        args.first
      end

      def min(args)
        Integer.new(args.map(&:value).min)
      end

      def max(args)
        Integer.new(args.map(&:value).max)
      end

    end

  end

end
