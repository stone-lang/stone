require "pry"
require "parslet"
require "stone/parser/parslet_extensions"


module Stone

  class Parser < Parslet::Parser

    include ParsletExtensions

    root(:top)

    rule(:top) {
      (line | blank_line).repeat
    }
    rule(:line) {
      whitespace? >> statement >> whitespace? >> (eol | line_comment.present?)
    }
    rule(:blank_line) {
      whitespace? >> line_comment.as(:comment).maybe >> eol
    }
    rule(:statement) {
      assignment | function_definition | expression
    }
    rule(:expression) {
      function_call | operation | literal | method_call | property_access | variable_reference | block | parens(whitespace? >> expression >> whitespace?)
    }
    rule!(:function_definition) {
      identifier.as(:name) >> str("(") >> parameter_list >> str(")") >> whitespace >> str(":=") >> whitespace >> str("function") >> whitespace? >> function_body
    }
    rule!(:parameter_list) {
      identifier.as(:parameter) >> (str(",") >> whitespace >> identifier.as(:parameter)).repeat(0)
    }
    rule(:function_body) {
      block
    }
    rule(:block) {
      str("{") >> (whitespace | eol).repeat(0) >> block_body.as(:block) >> (whitespace | eol).repeat(0) >> str("}")
    }
    rule(:block_body) {
      (statement >> (whitespace | eol).repeat(0)).repeat(1)
    }
    rule!(:assignment) {
      identifier.as(:lvalue) >> whitespace >> str(":=") >> whitespace >> expression.as(:rvalue)
    }
    rule!(:method_call) {
      # TODO: This should really be an expression instead of a variable reference.
      variable_reference.as(:object) >> str(".") >> identifier.as(:method) >> str("(") >> argument_list >> str(")")
    }
    rule!(:property_access) {
      # TODO: This should really be an expression instead of a variable reference.
      variable_reference.as(:object) >> str(".") >> identifier.as(:property)
    }
    rule!(:function_call) {
      identifier.as(:identifier) >> str("(") >> argument_list.maybe >> str(")")
    }
    rule!(:argument_list) {
      expression.as(:argument) >> (str(",") >> whitespace >> expression.as(:argument)).repeat(0)
    }
    rule(:operation) {
      unary_operation | binary_operation
    }
    rule!(:variable_reference) {
      identifier
    }
    rule(:literal) {
      boolean | integer | text
    }
    rule!(:boolean) {
      str("TRUE") | str("FALSE")
    }
    rule!(:integer) {
      binary_integer | octal_integer | hexadecimal_integer | decimal_integer
    }
    rule!(:text) {
      str('"').ignore >> (str('"').absent? >> any).repeat(0) >> str('"').ignore
    }
    rule!(:unary_operation) {
      unary_operator.repeat(1).as(:operator) >> unary_operand.as(:operand) >> whitespace?
    }
    rule!(:binary_operation) {
      binary_operand.as(:operand) >> (whitespace >> binary_operator.as(:operator) >> whitespace >> binary_operand.as(:operand)).repeat(1) >> whitespace?
    }
    rule(:decimal_integer) {
      match["+-"].maybe >> match["0-9_"].repeat(1)
    }
    rule(:hexadecimal_integer) {
      match["+-"].maybe >> str("0x") >> match["[:xdigit:]"] >> match["[:xdigit:]_"].repeat(0)
    }
    rule(:octal_integer) {
      match["+-"].maybe >> str("0o") >> match["0-7"] >> match["0-7_"].repeat(0)
    }
    rule(:binary_integer) {
      match["+-"].maybe >> str("0b") >> match["0-1"] >> match["0-1_"].repeat(0)
    }
    rule(:unary_operator) {
      match["!¬"]
    }
    rule(:binary_operator) {
      text_operator | equality_operator | arithmetic_operator | comparison_operator | boolean_operator
    }
    rule(:binary_operand) {
      # Would prefer `(block | binary_operation).absent? >> expression`, but that blows the stack.
      function_call | unary_operation | literal | variable_reference | parens(whitespace? >> expression >> whitespace?)
    }
    rule(:unary_operand) {
      (block | operation).absent? >> expression
    }
    rule(:equality_operator) {
      str("==") | str("!=") | str("≠")
    }
    rule(:arithmetic_operator) {
      match["+➕"] | match["\\-−➖"] | match["\*×·✖️"] | str("<!") | str(">!")
    }
    rule(:comparison_operator) {
      str("<=") | str("≤") | str("<") | str(">=") | str("≥") | str(">")
    }
    rule(:text_operator) {
      str("++")
    }
    rule(:boolean_operator) {
      str("∧") | str("∨")
    }
    rule(:identifier) {
      match["[:alpha:]\\?_"] >> match["[:alnum:]\\?_"].repeat(0)
    }
    rule(:whitespace) {
      (block_comment | (eol.absent? >> match('\s'))).repeat(1)
    }
    rule(:whitespace?) {
      whitespace.maybe
    }
    rule(:eol) {
      str("\n")
    }
    rule(:eof) {
      any.absent?
    }
    rule(:line_comment) {
      str("#") >> (eol.absent? >> any).repeat(0)
    }
    rule(:block_comment) {
      str("/*") >> (str("*/").absent? >> any).repeat(0) >> str("*/")
    }

  end

end
