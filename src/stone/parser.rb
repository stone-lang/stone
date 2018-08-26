require "stone/ast/literal"
require "stone/ast/operation"

require "parslet"


module Stone

  module ParsletExtensions

    # A rule that outputs an AST node.
    def rule!(name, opts = {}, &definition)
      rule(name, opts) { self.instance_eval(&definition).as(name) }
    end

  end

  class Parser < Parslet::Parser

    extend ParsletExtensions

    root(:top)
    rule(:top) { (expression | whitespace).repeat }
    rule(:expression) { literal | operation | parens(expression) }
    rule(:literal) { literal_boolean | literal_integer | literal_text }
    rule(:operation) { unary_operation }
    rule!(:unary_operation) { unary_operator.as(:operator) >> expression.as(:operand) }
    rule!(:literal_boolean) { str("TRUE") | str("FALSE") }
    rule!(:literal_integer) { literal_binary_integer | literal_octal_integer | literal_hexadecimal_integer | literal_decimal_integer }
    rule!(:literal_text) { str('"').ignore >> (str('"').absent? >> any).repeat >> str('"').ignore }
    rule(:literal_decimal_integer) { match["+-"].maybe >> match["0-9"].repeat(1) }
    rule(:literal_hexadecimal_integer) { match["+-"].maybe >> str("0x") >> match["0-9a-fA-F"].repeat(1) }
    rule(:literal_octal_integer) { match["+-"].maybe >> str("0o") >> match["0-7"].repeat(1) }
    rule(:literal_binary_integer) { match["+-"].maybe >> str("0b") >> match["0-1"].repeat(1) }
    rule(:unary_operator) { match["!¬"] }
    rule(:whitespace) { match["\n\s\r\t"].repeat(1) }

    def parens(ex)
      str("(").ignore >> ex >> str(")").ignore
    end

  end


  class Transform < Parslet::Transform

    rule(literal_boolean: simple(:b)) { AST::LiteralBoolean.new(b) }
    rule(literal_integer: simple(:i)) { AST::LiteralInteger.new(i) }
    rule(literal_text: simple(:t)) { AST::LiteralText.new(t) }
    rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) { AST::UnaryOperation.new(op, arg) }

  end

end
