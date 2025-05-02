require "stone/language/variables"

# BEFORE:
#   Base -> Literals -> Operators -> Functions -> Variables -> Properties
# AFTER:
#   Base -> Literals -> Variables -> Functions -> Properties -> Operators



module Stone
  module Language
    class Functions < Variables

      def grammar
        Class.new(super) do |_klass|
          override rule!(:expression) { literal | function | chained_function_call | variable_reference | block | parenthetical_expression }
          rule!(:function) { lambda_operator >> parens(parameter_list) >> whitespace >> function_body }
          rule!(:parameter_list) { (parameter >> (str(",") >> whitespace >> parameter).repeat(0)).repeat(0) }
          rule!(:parameter) { identifier }
          rule(:function_body) { block }
          rule(:block) { curly_braces((whitespace | eol).repeat(0) >> block_body.as(:block) >> (whitespace | eol).repeat(0)) }
          rule(:block_body) { (statement >> (whitespace | eol).repeat(0)).repeat(1) }
          rule!(:chained_function_call) { subject >> function_call.repeat(0) }
          rule!(:function_call) { parens(argument_list.maybe) }
          rule!(:subject) { function_call | variable_reference | parenthetical_expression }
          rule!(:argument_list) { (argument >> (str(",") >> whitespace >> argument).repeat(0)).repeat(0) }
          rule!(:argument) { expression }
          rule(:lambda_operator) { (str("λ") | str("->")).ignore }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(expression: subtree(:e)) {
            debug?
            e
          }
          rule(argument: simple(:argument)) {
            argument
          }
          rule(chained_function_call: simple(:subject), calls: sequence(:calls)) {
            debug?
          }
          rule(function_call: {argument_list: sequence(:arguments)}) {
            AST::FunctionCall.new("FIXME", arguments)
          }
          rule(block: sequence(:block_body)) {
            AST::Block.new(block_body)
          }
          rule(parameter: simple(:parameter)) {
            parameter
          }
          rule(function: {parameter_list: sequence(:parameters), block: sequence(:body)}) {
            AST::Function.new(parameters, body)
          }
        end
      end
    end
  end
end
