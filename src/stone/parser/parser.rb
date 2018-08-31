require "parslet"
require "stone/parser/parslet_extensions"


module Stone

  class Parser < Parslet::Parser

    include ParsletExtensions

    root(:top)
    rule(:top) {
      ((line_comment | (expression >> line_comment.repeat(0))) >> (newline.present? | whitespace?) >> (newline | eof)).repeat
    }
    rule(:line_comment) {
      (newline.absent? >> whitespace?) >> (str("#") >> (newline.absent? >> any).repeat).as(:comment) >> (newline.present? | eof.present?)
    }
    rule(:expression) {
      operation | literal | parens(whitespace? >> expression >> whitespace?)
    }
    rule(:binary_operand) {
      unary_operation | literal | parens(whitespace? >> expression >> whitespace?)
    }
    rule(:unary_operand) {
      literal | parens(whitespace? >> expression >> whitespace?)
    }
    rule(:literal) {
      boolean | integer | text
    }
    rule(:operation) {
      unary_operation | binary_operation
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
      match["+-"].maybe >> match["0-9"].repeat(1)
    }
    rule(:hexadecimal_integer) {
      match["+-"].maybe >> str("0x") >> match["0-9a-fA-F"].repeat(1)
    }
    rule(:octal_integer) {
      match["+-"].maybe >> str("0o") >> match["0-7"].repeat(1)
    }
    rule(:binary_integer) {
      match["+-"].maybe >> str("0b") >> match["0-1"].repeat(1)
    }
    rule(:unary_operator) {
      match["!¬"]
    }
    rule(:binary_operator) {
      text_operator | equality_operator | arithmetic_operator | comparison_operator
    }
    rule(:equality_operator) {
      str("==") | str("!=") | str("≠")
    }
    rule(:arithmetic_operator) {
      match["+➕\\-−➖\*×·✖️"]
    }
    rule(:comparison_operator) {
      str("<=") | str("≤") | str("<") | str(">=") | str("≥") | str(">")
    }
    rule(:text_operator) {
      str("++")
    }
    rule(:whitespace) {
      (block_comment | match('\s')).repeat(1)
    }
    rule(:whitespace?) {
      (block_comment | match('\s')).repeat(0)
    }
    rule(:newline) {
      match('\n').repeat(1)
    }
    rule(:eof) {
      any.absent?
    }
    rule(:block_comment) {
      str("/*") >> (str("*/").absent? >> any).repeat >> str("*/")
    }

  end

end
