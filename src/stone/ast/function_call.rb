module Stone

  module AST

    class FunctionCall < Base

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
        __send__(name, evaluated_arguments)
      rescue NoMethodError
        Error.new("UnknownFunction", name)
      end

    private

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
