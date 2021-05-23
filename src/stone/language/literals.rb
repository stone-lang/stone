require "stone/language/base"


module Stone
  module Language
    class Literals < Base

      DECIMAL_EXPONENT_SYMBOL = "\u23E8" # NOTE: I'm not 100% sure this is an appropriate use of this symbol.

      def grammar
        Class.new(super) do |_klass|
          override rule(:expression) { literal | parenthetical_expression }
          rule(:literal) { decimal | rational | integer | text }
          rule!(:integer) { binary_integer | octal_integer | hexadecimal_integer | decimal_integer }
          rule!(:decimal) { decimal_integer >> str(".") >> unsigned_decimal_integer >> (match["eE#{DECIMAL_EXPONENT_SYMBOL}"] >> decimal_integer).maybe }
          rule!(:rational) { decimal_integer.as(:numerator) >> str("/") >> unsigned_decimal_integer.as(:denominator) }
          rule!(:text) { str('"').ignore >> (str('"').absent? >> any).repeat(0) >> str('"').ignore }
          rule(:decimal_integer) { sign.maybe >> unsigned_decimal_integer }
          rule(:unsigned_decimal_integer) { digit >> digit_.repeat(0) }
          rule(:hexadecimal_integer) { sign.maybe >> str("0x") >> xdigit >> xdigit_.repeat(0) }
          rule(:octal_integer) { sign.maybe >> str("0o") >> odigit >> odigit_.repeat(0) }
          rule(:binary_integer) { sign.maybe >> str("0b") >> bdigit >> bdigit_.repeat(0) }
          rule(:sign) { match["+-"] }
          rule(:digit) { match["[:digit:]"] }
          rule(:xdigit) { match["[:xdigit:]"] }
          rule(:odigit) { match["[0-7]"] }
          rule(:bdigit) { match["[0-1]"] }
          rule(:digit_) { digit | str("_") }
          rule(:xdigit_) { xdigit | str("_") }
          rule(:odigit_) { odigit | str("_") }
          rule(:bdigit_) { bdigit | str("_") }
        end
      end

      def transforms
        Class.new(super) do |_klass|

          rule(integer: simple(:i)) {
            AST::Integer.new(i)
          }
          rule(decimal: simple(:d)) {
            AST::Decimal.new(d)
          }
          rule(rational: {numerator: simple(:numerator), denominator: simple(:denominator)}) {
            # TODO: Need a better way to determine whether the denominator is 0.
            if denominator.to_s == "0"
              Builtin::Error.new("DivisionByZero", "invalid rational literal")
            else
              AST::Rational.new(numerator, denominator)
            end
          }
          rule(text: simple(:t)) {
            AST::Text.new(t)
          }

        end
      end
    end
  end
end
