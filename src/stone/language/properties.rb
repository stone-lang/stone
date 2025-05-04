require "debug"

require "stone/language/functions"

module Stone
  module Language
    class Properties < Functions

      def grammar
        Class.new(super) do |_klass|
          override rule!(:expression) { literal | function | block | chained_function_call_or_property_access | parenthetical_expression }
          rule!(:chained_function_call_or_property_access) { subject >> (function_call | property_access).repeat(0) }
          rule!(:property_access) { str(".").ignore >> property }
          rule!(:property) { identifier }

          override rule(:expression) { function | operation | function_call | literal | property_access_chain | variable_reference | block | parenthetical_expression } # rubocop:disable Layout/LineLength
          rule!(:property_access_chain) { (variable_reference | parenthetical_expression).as(:subject) >> (str(".") >> identifier.as(:property).repeat >> parens(argument_list.maybe).maybe) } # rubocop:disable Layout/LineLength
          rule!(:property_access_chain) { variable_reference.as(:subject) >> (str(".") >> identifier.as(:property).repeat >> parens(argument_list.maybe).maybe) } # rubocop:disable Layout/LineLength

          override rule!(:expression) { subject >> (property_access | function_call).repeat }
          rule!(:subject) { function | variable_reference | literal | block | parenthetical_expression }
          rule!(:function_call) { parens(argument_list.maybe) }
          rule!(:property_access) { str(".") >> identifier.as(:property) }


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
          rule(property: simple(:property)) {
            debug?
            property
          }
          rule(property_access: {subject: subtree(:subject), property: simple(:property)}) {
            debug?
            AST::PropertyAccess.new(subject, property)
          }
          rule(property_access: {subject: simple(:subject), property: simple(:property)}) {
            debug?
            AST::PropertyAccess.new(subject, property)
          }
          rule(chained_function_call_or_property_access: {subject: simple(:subject), calls: sequence(:calls)}) {
            debug?
          }
          rule(chained_function_call_or_property_access: sequence(:s)) {
            debug?
          }
          rule(chained_function_call_or_property_access: subtree(:s)) {
            debug?
            if s.is_a?(Array)
              begin
                if s.last.is_a?(Stone::AST::FunctionCall)
                  s.last.function = s.first
                  s.last
                elsif s.last.is_a?(Stone::AST::PropertyAccess)
                  s.last.subject = s.first
                  s.last
                else
                  debug?
                  fail s.last.class
                end
                subject = s[0][:subject]
                property = s[1][:property]
                if s[2] && s[2][:argument_list]
                  arguments = s[2][:argument_list]
                  AST::MethodCall.new(subject, property, arguments)
                else
                  AST::PropertyAccess.new(subject, property)
                end
              rescue Exception
                debug?
                s
              end
            elsif s.is_a?(Hash) && s.has_key?(:subject) && s.keys.count == 1
              debug?
              if s[:subject].is_a?(Array)
                function_name = s[:subject][0].name
                arguments = s[:subject][1][:argument_list]
                AST::FunctionCall.new(function_name, arguments)
              else
                s[:subject]
              end
            else
              debug?
              s
            end
          }
          rule(subject: subtree(:subject), function_call: sequence(:arguments)) {
            AST::FunctionCall.new(subject, arguments)
          }
          rule(subject: subtree(:subject)) {
            subject
          }
          rule(sequence(:s)) {
            debug?
            s
          }
          rule(expression: sequence(:expr)) {
            debug?
            if expr.is_a?(Array) && expr.second.is_a?(Hash) && expr.second.has_key?(:function_call)
              subject = ""
              method = ""
              arguments = []
              AST::Call.new(subject, method, arguments)
            else
              expr
            end
          }
        end
      end
    end
  end
end
