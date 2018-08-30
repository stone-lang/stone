module Stone

  module AST

    class BinaryOperation < Operation

      PLUS = /[+➕]/
      MINUS = /[-−➖]/
      TIMES = /[*×·✖️]/
      EQUALS = /==/ # Comment here as work-around for Ruby parsing bug in Atom.
      NOT_EQUALS = /!=|≠/

      attr_reader :operators
      attr_reader :operands

      def initialize(operators, operands)
        @operators = operators.map(&:to_s)
        @operands = operands
      end

      def evaluate
        return error?(operands) if error?(operands)
        return Error.new("MixedOperatorsError", "Add parentheses where appropriate") if disallowed_mixed_operators?
        if mixed_operators?
          evaluate_mixed_operations
        else
          evaluate_operation
        end
      end

      def evaluate_operation
        case operators.first
        when PLUS
          add(operands)
        when MINUS
          subtract(operands)
        when TIMES
          multiply(operands)
        when EQUALS
          equal(operands)
        when NOT_EQUALS
          !equal(operands)
        else
          Error.new("UnknownOperator", operators.first)
        end
      end

      def evaluate_mixed_operations
        operators.zip(operands.rest).chunk_while{ |x, y| x.first == y.first }.reduce(operands.first) do |a, x|
          BinaryOperation.new(x.map(&:first), [a] + x.map(&:last)).evaluate
        end
      end

      def add(operands)
        Integer.new(operands.map(&:evaluate).map(&:value).inject(0, &:+))
      end

      def subtract(operands)
        Integer.new(operands.rest.map(&:evaluate).map(&:value).inject(operands.first.value, &:-))
      end

      def multiply(operands)
        Integer.new(operands.map(&:evaluate).map(&:value).inject(1, &:*))
      end

      def equal(operands)
        Boolean.new(operands.map(&:evaluate).map{ |o| [o.type, o.value] }.uniq.length == 1)
      end

      ALLOWED_OPERATOR_MIXTURES = [%w[+ -], %w[* /]]

      def disallowed_mixed_operators?
        mixed_operators? && !ALLOWED_OPERATOR_MIXTURES.include?(operators.sort.uniq)
      end

      def mixed_operators?
        operators.uniq.size > 1
      end

    end

  end

end
