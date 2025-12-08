require "grammy/grammar"


module Stone
  class Grammar < Grammy::Grammar

    # Identifier and operator patterns
    ALPHA_IDENTIFIER = /[a-zA-Z_][a-zA-Z0-9_]*[!?]?/
    COMPARISON_OPERATOR = /(==|!=|<=|>=|≠|≤|≥|<|>)/

    start :program_unit

    # Program structure
    rule(:program_unit) { statement_list + eof }
    rule(:statement_list) { list(statement, separated_by: statement_separator, allow_repeated_separator: true) }
    rule(:statement_separator) { newline | semi }
    rule(:statement) { (definition | expression | comment) + (ws_no_nl? + comment)[0..1] }
    rule(:definition) { identifier + ws! + define_op + ws! + expression }

    # Expressions
    # Expression hierarchy (from lowest to highest precedence):
    # 1. comparison_operation (lowest - binary/variadic operators)
    # 2. postfix (function_call, property_access)
    # 3. primary (highest - atoms)
    #
    # Postfix expressions (function calls and property access) have higher precedence
    # than comparisons but can chain: obj.prop(args).other_prop
    # Comparisons can chain: 1 < 2 < 3 desugars to <(1, 2, 3)
    rule(:expression) { type_declaration | comparison_operation | postfix_expression }
    rule(:type_declaration) { identifier + ws! + str("::") + ws! + type_annotation }
    rule(:type_annotation) { identifier }
    rule(:comparison_operation) { postfix_expression + (ws! + comparison_operator + ws! + postfix_expression)[1..] }
    rule(:postfix_expression) { primary + (argument_list | property_accessor)[0..] }
    rule(:property_accessor) { str(".") + identifier }
    rule(:primary) { parens(expression) | literal | reference | lambda | block }
    rule(:argument_list) { parens(comma_separated(argument)) }
    rule(:argument) { expression }
    rule(:literal) { literal_boolean | literal_string | literal_i64 }
    rule(:reference) { identifier }
    rule(:lambda) { lambda_op + parameter_list + ws? + block }
    rule(:parameter_list) { parens(comma_separated(parameter, allow_trailing: false)) }
    rule(:parameter) { identifier }
    rule(:block) { braces(statement_list) }

    # Custom Matchers/Combinators
    # Match the passed-in matchers/combinators within parentheses, with whitespace allowed.
    def parens(submatchers)
      str("(") + ws? + submatchers + ws? + str(")")
    end

    # Match the passed-in matchers/combinators within curly braces, with whitespace allowed.
    def braces(submatchers)
      str("{") + ws? + submatchers + ws? + str("}")
    end

    # Match a comma-separated list, optionally allowing a trailing comma.
    def comma_separated(submatchers, allow_trailing: true)
      list(submatchers, separated_by: str(","), allow_trailing: allow_trailing)
    end

    # Match a list of matchers/combinators, separated by a specified separator.
    # - Supports allowing trailing separator (default: true)
    # - Supports allowing repeated consecutive separators (default: false)
    # - Supports minimum item count (default: 0)
    def list(items, separated_by:, allow_trailing: true, allow_repeated_separator: false, min: 0)
      list_repetition = min.zero? ? [0..] : [min..]
      items_with_separators = ws? + items + (separated_by + ws? + items)[0..]
      if allow_trailing
        trailing_repetition = allow_repeated_separator ? [0..] : [0..1]
        (items_with_separators + (separated_by + ws?)[*trailing_repetition])[*list_repetition]
      else
        items_with_separators[*list_repetition]
      end
    end

    # Identifiers
    terminal(:identifier) { Regexp.union(ALPHA_IDENTIFIER, COMPARISON_OPERATOR) }

    # Operators
    terminal(:comparison_operator) { COMPARISON_OPERATOR }
    terminal(:lambda_op) { "λ" }
    terminal(:define_op) { ":=" }

    # Literals
    rule(:literal_boolean) { reg(/(TRUE|FALSE)/) }
    # WARNING: String literal rule must come before comment rule to handle `#` inside strings correctly.
    rule(:literal_string) { reg(/"(?:[^"\\]|\\.)*"/) }
    # NOTE: Decimal must be last to avoid consuming `0` from the prefixes.
    rule(:literal_i64) { literal_i64_binary | literal_i64_octal | literal_i64_hex | literal_i64_decimal }
    terminal(:literal_i64_decimal) { /[+-]?\d+/ }
    terminal(:literal_i64_binary) { /[+-]?0b[01]+/ }
    terminal(:literal_i64_octal) { /[+-]?0o[0-7]+/ }
    terminal(:literal_i64_hex) { /[+-]?0x[0-9a-fA-F]+/ }

    # Whitespace and separators
    terminal(:comment) { /#[^\n\r]*/ } # Does **NOT** include trailing EOL.
    terminal(:newline) { /(\n|\r\n)/ }
    terminal(:semi) { ";" }
    terminal(:ws) { /[ \t\n\r]+/ }
    terminal(:ws_no_nl) { /[ \t]+/ }
    rule(:ws?) { ws[0..] } # White space is **allowed**.
    rule(:ws!) { ws[1..] } # White space is **required**.
    rule(:ws_no_nl?) { ws_no_nl[0..] }

  end
end
