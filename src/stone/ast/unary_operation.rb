module Stone

  module AST

    class UnaryOperation < Operation

      BOOLEAN_NOT = /[!¬]/

      attr_reader :operator
      attr_reader :operands
      attr_reader :operand

      def initialize(operator, operand)
        @operator = operator.to_s
        @operand = operand
        @operands = [operand] # Keep parent class happy.
      end

      def evaluate(context)
        evaluated_operand = operand.evaluate(context)
        return error?(evaluated_operand) if error?(evaluated_operand)
        case operator
        when BOOLEAN_NOT
          boolean_not(evaluated_operand)
        else
          Error.new("UnknownOperator", operator)
        end
      end

      def boolean_not(operand)
        return Error.new("TypeError", "Boolean NOT operand must be a Boolean value: #{operand}") unless operand.is_a?(Boolean)
        return operand.to_s if operator.size.even?
        Boolean.new(!operand.value)
      end

    end

  end

end
