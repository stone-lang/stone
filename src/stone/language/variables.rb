require "stone/language/functions"


module Stone
  module Language
    class Variables < Functions

      def grammar
        Class.new(super) do |_klass|
          override rule(:statement) { assignment | expression }
          override rule(:expression) { function | operation | function_call | literal | variable_reference | block | parenthetical_expression }
          rule!(:assignment) { identifier.as(:lvalue) >> whitespace >> str(":=") >> whitespace >> expression.as(:rvalue) }
          rule!(:variable_reference) { identifier }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(assignment: {lvalue: simple(:lvalue), rvalue: simple(:rvalue)}) {
            AST::Assignment.new(lvalue, rvalue)
          }
          rule(variable_reference: simple(:v)) {
            AST::VariableReference.new(v)
          }
        end
      end
    end
  end
end
