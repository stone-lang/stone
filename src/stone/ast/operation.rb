module Stone

  module AST

    class Operation

      attr_reader :operator
      attr_reader :operands

      def initialize(operator, operands)
        @operator = operator.to_s
        @operands = operands
      end

      def to_s
        "#{operator}(#{operands.join(', ')})"
      end

    end

  end

end


require "stone/ast/unary_operation"
