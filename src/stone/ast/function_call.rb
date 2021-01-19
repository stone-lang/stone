module Stone

  module AST

    class FunctionCall < Base

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

      def value
        self
      end

      def evaluate(context) # rubocop:disable Metrics/AbcSize
        evaluated_arguments = arguments.map{ |a| a.evaluate(context) }
        return error?(evaluated_arguments) if error?(evaluated_arguments)
        function = context[name]
        return Error.new("UnknownFunction", name) unless callable?(function)
        # TODO: Check argument types.
        return arity_error(function, arguments.count) unless correct_arity?(function, arguments.count)
        function.call(context, evaluated_arguments)
      end

      # NOTE: A (default) Class constructor can be called with 0 arguments; a function/method cannot.
      # NOTE: We can call a Block, but not using the function-call syntax. (The arity check is checking for that.)
      private def callable?(function)
        function.respond_to?(:call) && function.method(:call).arity == 2
      end

      private def correct_arity?(function, actual_argument_count)
        function.arity.include?(actual_argument_count)
      end

      private def arity_error(function, actual_argument_count)
        Error.new("ArityError", "'#{name}' expects #{arity_error_expected_text(function.arity)}, got #{actual_argument_count}")
      end

      private def arity_error_expected_text(expected_arity)
        if expected_arity == (1..1)
          "1 argument"
        elsif expected_arity.size == 1
          "#{expected_arity.first} arguments"
        elsif expected_arity.size == 2
          "#{expected_arity.first} or #{expected_arity.last} arguments"
        else
          "#{expected_arity} arguments"
        end
      end

    end

  end

end
