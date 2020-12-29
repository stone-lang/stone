require "stone/language/literals"


module Stone
  module Language
    class Operators < Literals

      def grammar
        Class.new(super) do |klass|
          override rule(:expression) { literal | operation }
          rule(:operation) { unary_operation | binary_operation }
          rule!(:unary_operation) { unary_operator.repeat(1).as(:operator) >> unary_operand.as(:operand) >> whitespace? }
          rule!(:binary_operation) { binary_operand >> (whitespace >> binary_operator >> whitespace >> binary_operand).repeat(1) >> whitespace? }
          rule(:unary_operator) { match["!¬"] }
          rule!(:binary_operator) { application_operator | string_operator | equality_operator | arithmetic_operator | comparison_operator | boolean_operator }
          # TODO: This should really be an expression (other than a binary_operation).
          rule!(:binary_operand) { function_call | unary_operation | literal | variable_reference | parenthetical_expression }
          rule(:unary_operand) { (block | operation).absent? >> expression }
          rule(:equality_operator) { str("==") | str("!=") | str("≠") }
          rule(:arithmetic_operator) { match["+➕"] | match["\\-−➖"] | match["\*×·✖️"] | match["/÷➗∕"] | str("<!") | str(">!") }
          rule(:comparison_operator) { str("<=") | str("≤") | str("<") | str(">=") | str("≥") | str(">") }
          rule(:string_operator) { str("++") }
          rule(:boolean_operator) { str("∧") | str("∨") }
          rule(:application_operator) { str("|>") | str("<|") }

        end
      end

      def transforms
        Class.new(super) do |klass|
          rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) {
            AST::UnaryOperation.new(op, arg)
          }
          rule(binary_operation: subtree(:s)) {
            operators = s.rest.map_dig(:binary_operator)
            operands = s.map_dig(:binary_operand)
            AST::BinaryOperation.new(operators, operands)
          }
        end
      end
    end
  end
end
