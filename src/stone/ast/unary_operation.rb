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

      def to_s
        case operator
        when BOOLEAN_NOT
          boolean_not
        else
          fail "Unknown unary operator: #{operator}"
        end
      end

      def boolean_not
        fail "Boolean NOT operand must be a Boolean value: #{operand}" unless operand.is_a?(Boolean)
        return operand.to_s if operator.size.even?
        if operand.value == true
          Boolean.new(false).to_s
        else
          Boolean.new(true).to_s
        end
      end

    end

  end

end
