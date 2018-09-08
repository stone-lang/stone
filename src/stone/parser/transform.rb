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
    rule(function_call: {identifier: simple(:function_name)}) {
      AST::FunctionCall.new(function_name, [])
    }
    rule(function_call: {identifier: simple(:function_name), argument_list: subtree(:arguments)}) {
      args = [arguments].flatten.map{ |a| a[:argument] }
      args = args.map{ |a| a.is_a?(Hash) && a.has_key?(:block) ? AST::Block.new(a[:block]) : a }
      AST::FunctionCall.new(function_name, args)
    }
    rule(method_call: {object: simple(:object), method: simple(:method), argument_list: {argument: simple(:arg)}}) {
      AST::MethodCall.new(object, method, [arg])
    }
    rule(property_access: {object: simple(:object), property: simple(:property)}) {
      AST::PropertyAccess.new(object, property)
    }
    rule(function_definition: {name: simple(:name), parameter_list: subtree(:parameters), block: sequence(:body)}) {
      params = [parameters].flatten.map{ |p| p[:parameter] }
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
    rule(assignment: {lvalue: simple(:lvalue), rvalue: simple(:rvalue)}) {
      AST::Assignment.new(lvalue, rvalue)
    }
    rule(variable_reference: simple(:v)) {
      AST::VariableReference.new(v)
    }

  end

end
