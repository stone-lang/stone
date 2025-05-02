require "stone/language/literals"

# NOTE: Variables have to come before Function Calls and Property Access, because those depend on it.
module Stone
  module Language
    class Variables < Literals

      def grammar
        Class.new(super) do |_klass|
          override rule(:statement) { definition | expression }
          override rule!(:expression) { literal | variable_reference | parenthetical_expression }
          rule!(:definition) { lvalue >> whitespace >> str(":=") >> whitespace >> rvalue }
          rule!(:lvalue) { identifier }
          rule!(:rvalue) { expression }
          rule!(:variable_reference) { identifier }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(definition: {lvalue: simple(:lvalue), rvalue: subtree(:rvalue)}) {
            AST::Definition.new(lvalue, rvalue) # FIXME: Probably need to get the `expression` out.
          }
          rule(variable_reference: simple(:v)) {
            AST::VariableReference.new(v)
          }
        end
      end
    end
  end
end
