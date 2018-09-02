require "stone/ast/base"

require "extensions/enumerable"
require "parslet"
require "pry"


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
    rule(function_definition: subtree(:s)) {
      name = s[:name]
      params = [s[:parameter_list]].flatten.map{ |p| p[:parameter].to_s }
      body = s[:block_body]
      AST::Function.new(name, params, body)
    }

    rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) {
      AST::UnaryOperation.new(op, arg)
    }
    rule(binary_operation: subtree(:s)) {
      operators = s.rest.map_dig(:operator)
      operands = s.map_dig(:operand)
      AST::BinaryOperation.new(operators, operands)
    }
    rule(assignment: subtree(:s)) {
      AST::Assignment.new(s[:lvalue], s[:rvalue])
    }
    rule(variable_reference: simple(:v)) {
      AST::VariableReference.new(v)
    }

  end

end
