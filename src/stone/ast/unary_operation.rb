module Stone

  module AST

    class UnaryOperation < Operation

      BOOLEAN_NOT = /[!¬]/

      attr_reader :operator
      attr_reader :operands
      attr_reader :operand

      def initialize(operator, operand)
        @operator = operator.to_s
        @operands = [operand]
        @operand = operand
      end

      def evaluate
        return error?(operands) if error?(operands)
        case operator
        when BOOLEAN_NOT
          boolean_not
        else
          Error.new("UnknownOperator", operator)
        end
      end

      def boolean_not
        return Error.new("TypeError", "Boolean NOT operand must be a Boolean value: #{operand}") unless operand.is_a?(Boolean)
        return operand.to_s if operator.size.even?
        Boolean.new(!operand.value)
      end

    end

  end

end