require "grammy/grammar"


module Stone
  class Grammar < Grammy::Grammar

    start :program_unit

    rule(:program_unit) { expression }
    rule(:expression) { literal }
    rule(:literal) { literal_i64 }
    rule(:literal_i64) { literal_i64_decimal }

    terminal(:literal_i64_decimal) { /[+-]?\d+/ }

  end
end
