require "extensions/boolean"


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
        "÷" => "/",
        "➗" => "/",
        "∕" => "/",
        "≠" => "!=",
        "≤" => "<=",
        "≥" => ">=",
      }
      BOOLEAN_OPERATOR_MAP = {
        "*" => "∧",
        "×" => "∧",
        "·" => "∧",
        "✖️" => "∧",
        "+" => "∨",
        "➕" => "∨",
      }
      OPERATION_RESULT_TYPES = {
        "+"   => Integer,
        "-"   => Integer,
        "*"   => Integer,
        "/"   => Rational,
        "<!"  => Integer,
        ">!"  => Integer,
        "=="  => Boolean,
        "!="  => Boolean,
        "<"   => Boolean,
        "<="  => Boolean,
        ">"   => Boolean,
        ">="  => Boolean,
        "∧"  => Boolean,
        "∨"  => Boolean,
        "++"  => Text,
      }
      OPERATIONS = {
        "<"   => ->(_operator, operands){ operands.each_cons(2).map{ |l, r| l.value < r.value }.all? },
        "<="  => ->(_operator, operands){ operands.each_cons(2).map{ |l, r| l.value <= r.value }.all? },
        ">"   => ->(_operator, operands){ operands.each_cons(2).map{ |l, r| l.value > r.value }.all? },
        ">="  => ->(_operator, operands){ operands.each_cons(2).map{ |l, r| l.value >= r.value }.all? },
        "=="  => ->(_operator, operands){ operands.map{ |o| [o.type, o.value] }.uniq.length == 1 },
        "!="  => ->(_operator, operands){ operands.map{ |o| [o.type, o.value] }.uniq.length != 1 },
        "++"  => ->(_operator, operands){ operands.map(&:value).join("") },
        ">!"  => ->(_operator, operands){ operands.map(&:value).max },
        "<!"  => ->(_operator, operands){ operands.map(&:value).min },
        "/"   => ->(_operator, operands){ operands.rest.map(&:value).reduce(operands.first.value){ |a, v| builtin_divide(a, v) } },
        DEFAULT: ->(operator, operands){ operands.rest.map(&:value).reduce(operands.first.value, operator.to_sym) }
      }
      ALLOWED_ARITHMETIC_MIXTURES = [%w[+ -], %w[* /]]
      ALLOWED_COMPARISON_MIXTURES = [%w[< <=], %w[> >=]]
      ALLOWED_OPERATOR_MIXTURES = ALLOWED_ARITHMETIC_MIXTURES + ALLOWED_COMPARISON_MIXTURES

      attr_reader :operators, :operator
      attr_reader :operands

      def initialize(operators, operands)
        @source_location = operands.first.source_location
        @operators = operators.map(&:to_s).map{ |o| OPERATOR_MAP.fetch(o){ o } }
        @operator = @operators.first
        @operands = operands
      end

      def evaluate(context)
        evaluated_operands = operands.map{ |o| o.evaluate(context) }
        return error?(evaluated_operands) if error?(evaluated_operands)
        return Error.new("MixedOperatorsError", "Add parentheses where appropriate") if disallowed_mixed_operators?
        if mixed_operators?
          evaluate_mixed_operations(operators, evaluated_operands)
        else
          evaluate_operation(operator, evaluated_operands)
        end
      end

      def evaluate_operation(operator, operands)
        return Error.new("UnknownOperator", operator) unless known_operator?(operator)
        operator = BOOLEAN_OPERATOR_MAP.fetch(operator){ operator } if operands.all?{ |o| o.is_a?(Boolean) }
        operation = OPERATIONS.fetch(operator){ OPERATIONS[:DEFAULT] }
        result_type = OPERATION_RESULT_TYPES[operator]
        result_type.new(operation.call(operator, operands))
      end

      def evaluate_mixed_operations(operators, operands)
        if ALLOWED_ARITHMETIC_MIXTURES.flatten.include?(operators.first)
          evaluate_mixed_arithmethic_operations(operators, operands)
        elsif ALLOWED_COMPARISON_MIXTURES.flatten.include?(operators.first)
          evaluate_mixed_comparison_operations(operators, operands)
        else
          fail "Compiler needs logic added to handle the case of mixing these operators: #{operators}"
        end
      end

      def disallowed_mixed_operators?
        mixed_operators? && !ALLOWED_OPERATOR_MIXTURES.include?(operators.sort.uniq)
      end

      def mixed_operators?
        operators.uniq.size > 1
      end

      def known_operator?(operator)
        OPERATION_RESULT_TYPES.include?(operator)
      end

      # You're not expected to understand how this works. I wrote it, and I don't really understand how it works.
      def evaluate_mixed_arithmethic_operations(operators, operands)
        operators.zip(operands.rest).chunk_while{ |x, y| x.first == y.first }.reduce(operands.first) do |a, x|
          evaluate_operation(x.first.first, [a] + x.map(&:last))
        end
      end

      # This is almost as bad. Maybe worse in some ways.
      def evaluate_mixed_comparison_operations(operators, operands)
        Boolean.new(operands.each_cons(2).zip(operators).reduce(true) { |a, x|
          a && evaluate_operation(x.last, x.first).value
        })
      end

      def self.builtin_divide(dividend, divisor)
        dividend = Rational.new(dividend) if dividend.is_a?(::Integer)
        divisor = Rational.new(divisor) if divisor.is_a?(::Integer)
        Rational.new((dividend.numerator * divisor.denominator), (dividend.denominator * divisor.numerator))
      end

    end

  end

end
