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
    rule(rational: {numerator: simple(:numerator), denominator: simple(:denominator)}) {
      rational = AST::Rational.new(numerator, denominator)
      if rational.denominator.zero?
        AST::Error.new("DivisionByZero", "invalid rational literal")
      else
        rational
      end
    }
    rule(text: simple(:t)) {
      AST::Text.new(t)
    }
    rule(argument: simple(:argument)) {
      argument
    }
    rule(function_call: {identifier: simple(:function_name), argument_list: sequence(:arguments)}) {
      AST::FunctionCall.new(function_name, arguments)
    }
    rule(block: sequence(:block_body)) {
      AST::Block.new(block_body)
    }
    rule(method_call: {object: simple(:object), method: simple(:method), argument_list: sequence(:arguments)}) {
      AST::MethodCall.new(object, method, arguments)
    }
    rule(property_access: {object: simple(:object), property: simple(:property)}) {
      AST::PropertyAccess.new(object, property)
    }
    rule(parameter: simple(:parameter)) {
      parameter
    }
    rule(function_definition: {name: simple(:name), parameter_list: sequence(:parameters), block: sequence(:body)}) {
      AST::Function.new(name, parameters, body)
    }
    rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) {
      AST::UnaryOperation.new(op, arg)
    }
    rule(binary_operation: subtree(:s)) {
      operators = s.rest.map_dig(:binary_operator)
      operands = s.map_dig(:binary_operand)
      AST::BinaryOperation.new(operators, operands)
    }
    rule(assignment: {lvalue: simple(:lvalue), rvalue: simple(:rvalue)}) {
      AST::Assignment.new(lvalue, rvalue)
    }
    rule(variable_reference: simple(:v)) {
      AST::VariableReference.new(v)
    }

  end

end
