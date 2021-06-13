require "stone/language/literals"


module Stone
  module Language
    class Operators < Literals

      def grammar
        Class.new(super) do |_klass|
          override rule(:expression) { literal | operation | parenthetical_expression }
          rule!(:operation) { operand >> (whitespace >> operator >> whitespace >> operand).repeat(1) >> whitespace? }
          # TODO: This should really be an expression (other than an operation).
          rule!(:operand) { function_call | literal | variable_reference | parenthetical_expression }
          rule!(:operator) { match(/\p{Letter}/).absent? >> identifier }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(operation: subtree(:s)) {
            operators = s.rest.map_dig(:operator)
            operands = s.map_dig(:operand)
            AST::BinaryOperation.new(operators, operands)
          }
        end
      end
    end
  end
end
