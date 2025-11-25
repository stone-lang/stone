require "stone/ast"


module Stone
  class AST
    class FunctionCall < Stone::AST

      attr_reader :function_name, :arguments

      def initialize(function_name, arguments)
        @function_name = function_name
        @arguments = arguments
        @name = :function_call
      end

      def to_llir(builder, mod)
        func = mod.lookup_function(function_name)

        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        validate_argument_count(func.function_type.argument_types.size)
        args = evaluate_arguments(builder, mod)
        builder.call(func, *args, "#{function_name}_result")
      end

      def to_s
        "#{function_name}(#{arguments.join(', ')})"
      end

      private def validate_argument_count(expected)
        return if arguments.length == expected

        fail "#{function_name}() requires exactly #{expected} arguments, got #{arguments.length}"
      end

      private def evaluate_arguments(builder, mod)
        arguments.map { |arg| arg.to_llir(builder, mod) }
      end

    end
  end
end
