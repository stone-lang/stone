require "stone/language/base"


module Stone
  module Language
    class Literals < Base

      DECIMAL_EXPONENT_SYMBOL = "\u23E8"

      def grammar
        Class.new(super) do |_klass|
          override rule(:expression) { literal | parenthetical_expression }
          rule(:literal) { decimal | rational | integer | string }
          rule!(:integer) { binary_integer | octal_integer | hexadecimal_integer | decimal_integer }
          rule!(:decimal) { decimal_integer >> str(".") >> unsigned_decimal_integer >> (match["eE#{DECIMAL_EXPONENT_SYMBOL}"] >> decimal_integer).maybe }
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
        Class.new(super) do |_klass|

          rule(integer: simple(:i)) {
            Stone::Builtin::Integer.new(i)
          }
          rule(decimal: simple(:d)) {
            Stone::Builtin::Decimal.new(d)
          }
          rule(rational: {numerator: simple(:numerator), denominator: simple(:denominator)}) {
            # TODO: Need a better way to determine whether the denominator is 0.
            if denominator.to_s == "0"
              Stone::Builtin::Error.new("DivisionByZero", "invalid rational literal")
            else
              Stone::Builtin::Rational.new(numerator, denominator)
            end
          }
          rule(string: simple(:t)) {
            Stone::Builtin::Text.new(t)
          }

        end
      end
    end
  end
end
