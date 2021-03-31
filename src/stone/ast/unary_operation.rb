module Stone

  module AST

    class UnaryOperation < Base

      BOOLEAN_NOT = /[!¬]/

      attr_reader :operator
      attr_reader :operand

      def initialize(operator, operand)
        @source_location = operator.line_and_column
        @operator = operator
        @operand = operand
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

      def to_s
        "#{operator}(#{operand})"
      end

      private def boolean_not(operand)
        return Error.new("TypeError", "Boolean NOT operand must be a Boolean value: #{operand}") unless operand.is_a?(Boolean)
        return operand.to_s if operator.size.even?
        Boolean.new(!operand.value)
      end

    end

  end

end
