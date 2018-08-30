module Stone

  module AST

    class BinaryOperation < Operation

      OPERATOR_MAP = {
        "➕" => "+",
        "−" => "-",
        "➖" => "-",
        "×" => "*",
        "·" => "*",
        "✖️" => "*",
        "≠" => "!=",
        "≤" => "<=",
        "≥" => ">=",
      }
      OPERATION_RESULT_TYPES = {
        "+"   => Integer,
        "-"   => Integer,
        "*"   => Integer,
        "=="  => Boolean,
        "!="  => Boolean,
        "<"   => Boolean,
        "<="  => Boolean,
        ">"   => Boolean,
        ">="  => Boolean,
      }
      OPERATIONS = {
        "=="  => ->(_operator, operands){ operands.map(&:evaluate).map{ |o| [o.type, o.value] }.uniq.length == 1 },
        "!="  => ->(_operator, operands){ operands.map(&:evaluate).map{ |o| [o.type, o.value] }.uniq.length != 1 },
        DEFAULT: ->(operator, operands){ operands.rest.map(&:evaluate).map(&:value).reduce(operands.first.evaluate.value, operator.to_sym) }
      }

      attr_reader :operators, :operator
      attr_reader :operands

      def initialize(operators, operands)
        @operators = operators.map(&:to_s).map{ |o| OPERATOR_MAP.fetch(o){ o } }
        @operator = @operators.first
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
        return Error.new("UnknownOperator", operator) unless known_operator?
        operation = OPERATIONS.fetch(operator){ OPERATIONS[:DEFAULT] }
        result_type = OPERATION_RESULT_TYPES[operator]
        result_type.new(operation.call(operator, operands))
      end

      def evaluate_mixed_operations
        operators.zip(operands.rest).chunk_while{ |x, y| x.first == y.first }.reduce(operands.first) do |a, x|
          BinaryOperation.new(x.map(&:first), [a] + x.map(&:last)).evaluate
        end
      end

      ALLOWED_OPERATOR_MIXTURES = [%w[+ -], %w[* /]]

      def disallowed_mixed_operators?
        mixed_operators? && !ALLOWED_OPERATOR_MIXTURES.include?(operators.sort.uniq)
      end

      def mixed_operators?
        operators.uniq.size > 1
      end

      def known_operator?
        OPERATION_RESULT_TYPES.include?(operator)
      end

    end

  end

end
