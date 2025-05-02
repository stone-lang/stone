module Stone

  module AST

    class FunctionCall < Expression

      attr_accessor :function
      attr_reader :arguments

      def initialize(function, arguments)
        debug?
        @source_location = function.line_and_column rescue nil # rubocop:disable Style/RescueModifier
        @name = name.to_s.to_sym
        @function = function
        @arguments = arguments
      end

      def to_s
        "#{function}(#{arguments.join(', ')})"
      end

      def value
        self
      end

      def evaluate(context)
        evaluated_function = function.evaluate(context)
        evaluated_arguments = arguments.map{ |a| a.evaluate(context) }
        return error?(evaluated_arguments) if error?(evaluated_arguments)
        # TODO: It'd be nice if we could display the name of the uncallable.
        return Builtin::Error.new("UnknownFunction") unless callable?(evaluated_function)
        # TODO: Check argument types.
        return arity_error(evaluated_function, arguments.count) unless correct_arity?(evaluated_function, arguments.count)
        evaluated_function.call(context, evaluated_arguments)
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
        # TODO: It'd be nice if we could display the name of the uncallable.
        Builtin::Error.new("ArityError", "expected #{arity_error_expected_text(function.arity)}, got #{actual_argument_count}")
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
