require "stone/language/functions"


module Stone
  module Language
    class Variables < Functions

      def grammar
        Class.new(super) do |_klass|
          override rule(:statement) { definition | expression }
          override rule(:expression) { function | operation | function_call | literal | variable_reference | block | parenthetical_expression }
          rule!(:definition) { identifier.as(:lvalue) >> whitespace >> str(":=") >> whitespace >> expression.as(:rvalue) }
          rule!(:variable_reference) { identifier }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(definition: {lvalue: simple(:lvalue), rvalue: simple(:rvalue)}) {
            AST::Definition.new(lvalue, rvalue)
          }
          rule(variable_reference: simple(:v)) {
            AST::VariableReference.new(v)
          }
        end
      end
    end
  end
end
