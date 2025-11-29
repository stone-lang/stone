require "grammy/grammar"


module Stone
  class Grammar < Grammy::Grammar

    start :program_unit

    rule(:program_unit) { statement_list }
    rule(:statement_list) { (ws[0..] + statement + (ws_no_nl[0..] + statement_separator)[0..1])[1..] }
    rule(:statement_separator) { comment | semi | newline | eof }
    rule(:statement) { comment | definition | expression | empty }
    rule(:definition) { identifier + ws[1..] + define_op + ws[1..] + expression }
    rule(:expression) { function_call | primary }
    rule(:function_call) { primary + argument_list }
    rule(:primary) { lambda | literal | reference }
    rule(:lambda) { lambda_symbol + parameter_list + ws[0..] + block }
    rule(:block) { lbrace + ws[0..] + block_body + ws[0..] + rbrace }
    rule(:block_body) { (ws[0..] + statement + (ws_no_nl[0..] + statement_separator)[0..1])[0..] }
    rule(:parameter_list) { lparen + ws[0..] + parameter_list_content + rparen }
    rule(:parameter_list_content) { (parameter + (comma + ws[0..] + parameter)[0..])[0..1] }
    rule(:parameter) { ws[0..] + identifier + ws[0..] }
    rule(:argument_list) { lparen + ws[0..] + argument_list_content + rparen }
    rule(:argument_list_content) { (argument + (comma + ws[0..] + argument)[0..])[0..1] }
    rule(:argument) { ws[0..] + expression + ws[0..] }
    rule(:reference) { identifier }
    rule(:literal) { literal_i64 }
    # NOTE: decimal has to come last, or else it'll read the `0` before a `b`, `o`, or `x`.
    rule(:literal_i64) { literal_i64_binary | literal_i64_octal | literal_i64_hex | literal_i64_decimal }

    terminal(:comment) { /#[^\n\r]*(?:\r\n|\n|\r)?/ } # NOTE: includes trailing EOL.
    terminal(:literal_i64_decimal) { /[+-]?\d+/ }
    terminal(:literal_i64_binary) { /[+-]?0b[01]+/ }
    terminal(:literal_i64_octal) { /[+-]?0o[0-7]+/ }
    terminal(:literal_i64_hex) { /[+-]?0x[0-9a-fA-F]+/ }
    terminal(:identifier) { /[a-zA-Z_][a-zA-Z0-9_]*/ }
    terminal(:lambda_symbol) { "λ" }
    terminal(:lparen) { "(" }
    terminal(:rparen) { ")" }
    terminal(:lbrace) { "{" }
    terminal(:rbrace) { "}" }
    terminal(:comma) { "," }
    terminal(:ws) { /[ \t\n\r]+/ }
    terminal(:ws_no_nl) { /[ \t]+/ }
    terminal(:newline) { /(\n|\r\n)/ }
    terminal(:semi) { ";" }
    terminal(:define_op) { ":=" }
    terminal(:empty) { "" }

  end
end
