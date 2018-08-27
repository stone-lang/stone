require "stone/ast/literal"
require "stone/ast/operation"

require "parslet"
require "stone/parser/parslet_extensions"


module Stone

  class Parser < Parslet::Parser

    include ParsletExtensions

    root(:top)
    rule(:top) { (expression | whitespace).repeat }
    rule(:expression) { parens(whitespace? >> expression >> whitespace?) | operation | literal }
    rule(:operand) { parens(whitespace? >> expression >> whitespace?) | unary_operation | literal }
    rule(:literal) { literal_boolean | literal_integer | literal_text }
    rule(:operation) { unary_operation | binary_operation }
    rule!(:literal_boolean) { str("TRUE") | str("FALSE") }
    rule!(:literal_integer) { literal_binary_integer | literal_octal_integer | literal_hexadecimal_integer | literal_decimal_integer }
    rule!(:literal_text) { str('"').ignore >> (str('"').absent? >> any).repeat >> str('"').ignore }
    rule!(:unary_operation) { unary_operator.as(:operator) >> operand.as(:operand) >> whitespace? }
    rule!(:binary_operation) { operand.as(:operand0) >> whitespace >> binary_operator.as(:operator) >> whitespace >> operand.as(:operand) >> whitespace? }
    rule(:literal_decimal_integer) { match["+-"].maybe >> match["0-9"].repeat(1) }
    rule(:literal_hexadecimal_integer) { match["+-"].maybe >> str("0x") >> match["0-9a-fA-F"].repeat(1) }
    rule(:literal_octal_integer) { match["+-"].maybe >> str("0o") >> match["0-7"].repeat(1) }
    rule(:literal_binary_integer) { match["+-"].maybe >> str("0b") >> match["0-1"].repeat(1) }
    rule(:unary_operator) { match["!¬"] }
    rule(:binary_operator) { match["+➕\\-−➖\*×·✖️"] }
    rule(:whitespace) { match('\s').repeat(1) }
    rule(:whitespace?) { match('\s').repeat(0) }

  end

end
