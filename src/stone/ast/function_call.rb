module Stone

  module AST

    class FunctionCall < Base

      attr_reader :name
      attr_reader :arguments

      def initialize(name, arguments)
        @name = name.to_s.to_sym
        @arguments = arguments.map(&:evaluate)
      end

      def to_s
        "#{name}(#{arguments.join(', ')})"
      end

      def evaluate
        return error?(arguments) if error?(arguments)
        __send__(name, arguments)
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
