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
        # For chained comparisons, generate inline comparison logic
        return generate_chained_comparison(builder, mod) if chained_comparison?

        # Regular function call
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        validate_argument_count(func.function_type.argument_types.size)
        args = evaluate_arguments(builder, mod)
        builder.call(func, *args, "#{function_name}_result")
      end

      def to_s
        "#{function_name}(#{arguments.join(', ')})"
      end

      private def chained_comparison?
        comparison_operator? && arguments.length > 2
      end

      private def comparison_operator?
        %w[== != ≠ < <= ≤ > >= ≥].include?(function_name)
      end

      private def generate_chained_comparison(builder, mod)
        # Generate inline code for chained comparisons
        # <(a, b, c) generates: (a < b) && (b < c)
        func = lookup_comparison_function(mod)
        args = evaluate_arguments(builder, mod)
        build_chained_and(builder, func, args)
      end

      private def lookup_comparison_function(mod)
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        func
      end

      private def build_chained_and(builder, func, args)
        result = builder.call(func, args[0], args[1], "cmp_0")

        (1...args.length - 1).each do |i|
          pair_result = builder.call(func, args[i], args[i + 1], "cmp_#{i}")
          result = builder.and(result, pair_result, "and_#{i}")
        end

        result
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
