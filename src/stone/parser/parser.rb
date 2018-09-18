require "pry"
require "parslet"
require "stone/parser/parslet_extensions"


module Stone

  class Parser < Parslet::Parser

    include ParsletExtensions

    root(:top)

    rule(:top) {
      line.repeat
    }
    rule(:line) {
      statement_line | blank_line
    }
    rule(:statement_line) {
      whitespace? >> statement >> whitespace? >> (eol | line_comment.present?)
    }
    rule(:blank_line) {
      whitespace? >> line_comment.as(:comment).maybe >> eol
    }
    rule(:statement) {
      assignment | expression
    }
    rule(:expression) {
      function | operation | function_call | literal | method_call | property_access | variable_reference | block | parenthetical_expression
    }
    rule(:parenthetical_expression) {
      parens(whitespace? >> expression >> whitespace?)
    }
    rule!(:function) {
      str("(") >> parameter_list >> str(")") >> whitespace >> str("=>") >> whitespace >> function_body
    }
    rule!(:parameter_list) {
      (parameter >> (str(",") >> whitespace >> parameter).repeat(0)).repeat(0)
    }
    rule!(:parameter) {
      identifier
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
      (argument >> (str(",") >> whitespace >> argument).repeat(0)).repeat(0)
    }
    rule!(:argument) {
      expression
    }
    rule(:operation) {
      unary_operation | binary_operation
    }
    rule!(:variable_reference) {
      identifier
    }
    rule(:literal) {
      boolean | rational | integer | text
    }
    rule!(:boolean) {
      str("TRUE") | str("FALSE")
    }
    rule!(:integer) {
      binary_integer | octal_integer | hexadecimal_integer | decimal_integer
    }
    rule!(:rational) {
      decimal_integer.as(:numerator) >> str("/") >> unsigned_decimal_integer.as(:denominator)
    }
    rule!(:text) {
      str('"').ignore >> (str('"').absent? >> any).repeat(0) >> str('"').ignore
    }
    rule!(:unary_operation) {
      unary_operator.repeat(1).as(:operator) >> unary_operand.as(:operand) >> whitespace?
    }
    rule!(:binary_operation) {
      binary_operand >> (whitespace >> binary_operator >> whitespace >> binary_operand).repeat(1) >> whitespace?
    }
    rule(:decimal_integer) {
      match["+-"].maybe >> unsigned_decimal_integer
    }
    rule(:unsigned_decimal_integer) {
      match["0-9_"].repeat(1)
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
    rule!(:binary_operator) {
      application_operator | text_operator | equality_operator | arithmetic_operator | comparison_operator | boolean_operator
    }
    rule!(:binary_operand) {
      # TODO: This should really be an expression (other than a binary_operation).
      function_call | unary_operation | literal | variable_reference | parenthetical_expression
    }
    rule(:unary_operand) {
      (block | operation).absent? >> expression
    }
    rule(:equality_operator) {
      str("==") | str("!=") | str("≠")
    }
    rule(:arithmetic_operator) {
      match["+➕"] | match["\\-−➖"] | match["\*×·✖️"] | match["/÷➗∕"] | str("<!") | str(">!")
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
    rule(:application_operator) {
      str("|>") | str("<|")
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
