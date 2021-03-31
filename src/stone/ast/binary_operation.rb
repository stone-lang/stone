require "extensions/boolean"


module Stone

  module AST

    class BinaryOperation < Base

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
        "+" => Number,
        "-" => Number,
        "*" => Number,
        "/" => Rational,
        "<!" => Number,
        ">!" => Number,
        "==" => Boolean,
        "!=" => Boolean,
        "<" => Boolean,
        "<=" => Boolean,
        ">" => Boolean,
        ">=" => Boolean,
        "∧" => Boolean,
        "∨" => Boolean,
        "++" => Text,
        "|>" => Any,
        "<|" => Any,
      }
      OPERATIONS = {
        "<" => ->(_c, _o, operands){ operands.map(&:normalized!).each_cons(2).map{ |l, r| l.value < r.value }.all? },
        "<=" => ->(_c, _o, operands){ operands.map(&:normalized!).each_cons(2).map{ |l, r| l.value <= r.value }.all? },
        ">" => ->(_c, _o, operands){ operands.map(&:normalized!).each_cons(2).map{ |l, r| l.value > r.value }.all? },
        ">=" => ->(_c, _o, operands){ operands.map(&:normalized!).each_cons(2).map{ |l, r| l.value >= r.value }.all? },
        "==" => ->(_c, _o, operands){ operands.map{ |o| n = o.normalized!; [n.type, n.value] }.uniq.length == 1 }, # rubocop:disable Style/Semicolon
        "!=" => ->(_c, _o, operands){ operands.map{ |o| n = o.normalized!; [n.type, n.value] }.uniq.length != 1 }, # rubocop:disable Style/Semicolon
        "++" => ->(_c, _o, operands){ operands.map(&:value).join("") },
        ">!" => ->(_c, _o, operands){ operands.map(&:value).max },
        "<!" => ->(_c, _o, operands){ operands.map(&:value).min },
        "|>" => ->(ct, _o, operands){ operands.reduce{ |l, r| r.call(ct, [l]) } },
        "<|" => ->(ct, _o, operands){ operands.reverse.reduce{ |r, l| l.call(ct, [r]) } },
        "/" => ->(_c, _o, operands){ operands.map(&:value).reduce{ |a, v| builtin_divide(a, v) } },
        DEFAULT: ->(_c, operator, operands){ operands.map(&:value).reduce(operator.to_sym) }
      }
      LOWER_PRECEDENCE_OPERATORS = %w[== != < <= > >=]
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
          evaluate_mixed_operations(context, operators, evaluated_operands)
        else
          evaluate_operation(context, operator, evaluated_operands)
        end
      end

      def self.builtin_divide(dividend, divisor)
        dividend = Rational.new(dividend) if dividend.is_a?(::Integer)
        divisor = Rational.new(divisor) if divisor.is_a?(::Integer)
        # Note that we're returning a native Ruby `Rational` here.
        Rational((dividend.numerator * divisor.denominator), (dividend.denominator * divisor.numerator))
      end

      # TODO: This should probably have a unit test.
      def to_s
        operands.zip(operators).flatten.compact.map{ |n| n.respond_to?(:source_code) ? n.source_code : n.to_s }.join(" ")
      end

      private def evaluate_operation(context, operator, operands)
        return Error.new("UnknownOperator", operator) unless known_operator?(operator)
        operator = BOOLEAN_OPERATOR_MAP.fetch(operator){ operator } if operands.all?{ |o| o.is_a?(Boolean) }
        operation = OPERATIONS.fetch(operator){ OPERATIONS[:DEFAULT] }
        result_type = OPERATION_RESULT_TYPES[operator]
        result_type.new!(operation.call(context, operator, operands))
      end

      private def evaluate_mixed_operations(context, operators, operands) # rubocop:disable Metrics/AbcSize
        if (ALLOWED_ARITHMETIC_MIXTURES.flatten & operators).sort == operators.sort.uniq
          evaluate_mixed_arithmethic_operations(context, operators, operands)
        elsif (ALLOWED_COMPARISON_MIXTURES.flatten & operators).sort == operators.sort.uniq
          evaluate_mixed_comparison_operations(context, operators, operands)
        elsif !(LOWER_PRECEDENCE_OPERATORS & operators).empty?
          evaluate_lower_precedence_operations(context, operators, operands)
        else
          fail "Compiler needs logic added to handle the case of mixing these operators: #{operators}"
        end
      end

      private def disallowed_mixed_operators?
        mixed_operators? && !allowed_mixed_operators?
      end

      private def mixed_operators?
        operators.uniq.size > 1
      end

      private def allowed_mixed_operators?
        (operators & LOWER_PRECEDENCE_OPERATORS).any? || ALLOWED_OPERATOR_MIXTURES.include?(operators.sort.uniq)
      end

      private def known_operator?(operator)
        OPERATION_RESULT_TYPES.has_key?(operator)
      end

      # This one's a bit rough, but we should probably make it more like evaluate_mixed_arithmethic_operations.
      private def evaluate_lower_precedence_operations(context, operators, operands) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        expr = operands.zip(operators).flatten.compact.each_cons(3).map { |ops|
          if !ops[1].is_a?(String)
            nil
          elsif LOWER_PRECEDENCE_OPERATORS.include?(ops[1])
            ops[1]
          else
            evaluate_operation(context, ops[1], [ops[0], ops[2]])
          end
        }.compact
        expr = [operands.first] + expr if expr.first.is_a?(String)
        expr = expr + [operands.last] if expr.last.is_a?(String)
        remaining_operators = expr.select{ |x| x.is_a?(String) }
        remaining_operands = expr.reject{ |x| x.is_a?(String) }
        evaluate_mixed_comparison_operations(context, remaining_operators, remaining_operands)
      end

      # You're not expected to understand how this works. I wrote it, and I don't really understand how it works.
      private def evaluate_mixed_arithmethic_operations(context, operators, operands)
        operators.zip(operands.rest).chunk_while{ |x, y| x.first == y.first }.reduce(operands.first) do |a, x|
          evaluate_operation(context, x.first.first, [a] + x.map(&:last))
        end
      end

      # This is almost as bad. Maybe worse in some ways.
      private def evaluate_mixed_comparison_operations(context, operators, operands)
        Boolean.new(operands.each_cons(2).zip(operators).reduce(true) { |a, x|
          a && evaluate_operation(context, x.last, x.first).value
        })
      end

    end

  end

end
