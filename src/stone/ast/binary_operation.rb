module Stone

  module AST

    class BinaryOperation < Operation

      PLUS = /[+➕]/
      MINUS = /[-−➖]/
      TIMES = /[*×·✖️]/

      attr_reader :operators
      attr_reader :operands

      def initialize(operators, operands)
        @operators = operators.map(&:to_s)
        @operands = operands
      end

      def evaluate
        return error?(operands) if error?(operands)
        return Error.new("MixedOperatorsError", "Add parentheses where appropriate") if disallowed_mixed_operators?
        case operators.first
        when PLUS
          add(operands)
        when MINUS
          subtract(operands)
        when TIMES
          multiply(operands)
        else
          Error.new("UnknownOperator", operators.first)
        end
      end

      def add(operands)
        Integer.new(operands.map(&:value).inject(0, &:+)).to_s
      end

      def subtract(operands)
        Integer.new(operands[1..-1].map(&:value).inject(operands.first.value, &:-)).to_s
      end

      def multiply(operands)
        Integer.new(operands.map(&:value).inject(1, &:*)).to_s
      end

      def disallowed_mixed_operators?
        mixed_operators?
      end

      def mixed_operators?
        operators.uniq.size > 1
      end

    end

  end

end
