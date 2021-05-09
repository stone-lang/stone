require "stone/language/variables"


module Stone
  module Language
    class Objects < Variables

      def grammar
        Class.new(super) do |_klass|
          override rule(:expression) { function | operation | function_call | literal | method_call | property_access | variable_reference | block | parenthetical_expression } # rubocop:disable Layout/LineLength
          rule!(:method_call) { variable_reference.as(:object) >> str(".") >> identifier.as(:method) >> parens(argument_list) }
          # TODO: This should really be an expression instead of a variable reference.
          rule!(:property_access) { variable_reference.as(:object) >> str(".") >> identifier.as(:property) }
        end
      end

      def transforms
        Class.new(super) do |_klass|
          rule(method_call: {object: simple(:object), method: simple(:method), argument_list: sequence(:arguments)}) {
            AST::MethodCall.new(object, method, arguments)
          }
          rule(property_access: {object: simple(:object), property: simple(:property)}) {
            AST::PropertyAccess.new(object, property)
          }
        end
      end
    end
  end
end
