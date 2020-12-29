require "stone/language/base"


module Stone
  module Language
    class Literals < Base

      def grammar
        Class.new(super) do |klass|
          override rule(:expression) { literal | parenthetical_expression }
          rule(:literal) { decimal | rational | integer | string }
          rule!(:integer) { binary_integer | octal_integer | hexadecimal_integer | decimal_integer }
          rule!(:decimal) { decimal_integer >> str(".") >> unsigned_decimal_integer >> (match["eE\u23E8"] >> decimal_integer).maybe }  # NOTE: \u23E8 is Unicode DECIMAL EXPONENT SYMBOL.
          rule!(:rational) { decimal_integer.as(:numerator) >> str("/") >> unsigned_decimal_integer.as(:denominator) }
          rule!(:string) { str('"').ignore >> (str('"').absent? >> any).repeat(0) >> str('"').ignore }
          rule(:decimal_integer) { match["+-"].maybe >> unsigned_decimal_integer }
          rule(:unsigned_decimal_integer) { match["0-9_"].repeat(1) }
          rule(:hexadecimal_integer) { match["+-"].maybe >> str("0x") >> match["[:xdigit:]"] >> match["[:xdigit:]_"].repeat(0) }
          rule(:octal_integer) { match["+-"].maybe >> str("0o") >> match["0-7"] >> match["0-7_"].repeat(0) }
          rule(:binary_integer) { match["+-"].maybe >> str("0b") >> match["0-1"] >> match["0-1_"].repeat(0) }
        end
      end

      def transforms
        Class.new(super) do |klass|

          rule(integer: simple(:i)) {
            AST::Integer.new(i)
          }
          rule(decimal: simple(:d)) {
            AST::Decimal.new(d)
          }
          rule(rational: {numerator: simple(:numerator), denominator: simple(:denominator)}) {
            # TODO: Need a better way to determine whether the denominator is 0.
            denominator.to_s == "0" ? AST::Error.new("DivisionByZero", "invalid rational literal") : AST::Rational.new(numerator, denominator)
          }
          rule(string: simple(:t)) {
            AST::Text.new(t)
          }

        end
      end
    end
  end
end