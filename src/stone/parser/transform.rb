require "stone/ast/base"

require "extensions/enumerable"
require "parslet"


module Stone

  class Transform < Parslet::Transform

    rule(comment: simple(:c)) {
      AST::Comment.new(c)
    }
    rule(boolean: simple(:b)) {
      AST::Boolean.new(b)
    }
    rule(integer: simple(:i)) {
      AST::Integer.new(i)
    }
    rule(text: simple(:t)) {
      AST::Text.new(t)
    }
    rule(function_call: subtree(:s)) {
      identifier = [s].flatten.first[:identifier]
      arguments = [s].flatten.map{ |a| a[:argument] }.compact
      AST::FunctionCall.new(identifier, arguments)
    }
    rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) {
      AST::UnaryOperation.new(op, arg)
    }
    rule(binary_operation: subtree(:s)) {
      operators = s.rest.map_dig(:operator)
      operands = s.map_dig(:operand)
      AST::BinaryOperation.new(operators, operands)
    }

  end

end
