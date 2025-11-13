require "grammy/grammar"


module Stone
  class Grammar < Grammy::Grammar

    start :program_unit

    rule(:program_unit) { expression }
    rule(:expression) { literal }
    rule(:literal) { literal_i64 }
    # NOTE: decimal has to come last, or else it'll read the `0` before a `b`, `o`, or `x`.
    rule(:literal_i64) { literal_i64_binary | literal_i64_octal | literal_i64_hex | literal_i64_decimal }

    terminal(:literal_i64_decimal) { /[+-]?\d+/ }
    terminal(:literal_i64_binary) { /[+-]?0b[01]+/ }
    terminal(:literal_i64_octal) { /[+-]?0o[0-7]+/ }
    terminal(:literal_i64_hex) { /[+-]?0x[0-9a-fA-F]+/ }

  end
end
