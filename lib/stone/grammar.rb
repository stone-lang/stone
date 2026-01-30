require "grammy/grammar"


module Stone
  class Grammar < Grammy::Grammar

    # Identifier and operator patterns
    ALPHA_IDENTIFIER = /[a-zA-Z_][a-zA-Z0-9_]*[!?]?/
    COMPUTED_PROPERTY_ID = /[A-Z][a-zA-Z0-9_]*@[a-zA-Z_][a-zA-Z0-9_]*[!?]?/
    COMPARISON_OPERATOR = /(==|!=|<=|>=|≠|≤|≥|<|>)/
    BOOLEAN_OPERATOR = /(∧|∨|⊻|¬)/

    start :program_unit

    # Program structure
    rule(:program_unit) { statement_list + eof }
    rule(:statement_list) { list(statement, separated_by: statement_separator, allow_repeated_separator: true) }
    rule(:statement_separator) { newline | semi }
    rule(:statement) { (definition | expression | comment) + (ws_no_nl? + comment)[0..1] }
    rule(:definition) { (computed_property_id | identifier) + ws! + define_op + ws! + expression }

    # Expressions
    # Expression hierarchy (from lowest to highest precedence):
    # 1. comparison_operation (lowest - binary/variadic operators)
    # 2. boolean_operation (binary/variadic boolean operators)
    # 3. postfix (function_call, property_access)
    # 4. primary (highest - atoms)
    #
    # Comparisons operate on boolean operations, which operate on postfix expressions.
    # boolean_operation with zero operators is equivalent to postfix_expression.
    # This allows mixing with parentheses: (5 < 3) ∧ TRUE
    # Both can chain: 1 < 2 < 3 desugars to <(1, 2, 3)
    rule(:expression) { type_declaration | comparison_operation | boolean_operation }
    rule(:type_declaration) { identifier + ws! + str("::") + ws! + type_annotation }
    rule(:type_annotation) { type_union }
    rule(:type_union) { type_term + (ws? + str("|") + ws? + type_term)[0..] }
    rule(:type_term) { type_function | parameterized_type | parens(type_annotation) | type_name }
    rule(:parameterized_type) { type_name + parens(comma_separated(type_annotation, allow_trailing: false)) }
    rule(:type_function) { type_params + ws? + str("->") + ws? + type_return }
    rule(:type_params) { parens(comma_separated(type_annotation, allow_trailing: false)) }
    rule(:type_return) { type_return_union | parens(type_annotation) }
    rule(:type_return_union) { type_name + (ws? + str("|") + ws? + type_name)[0..] }
    rule(:type_name) { identifier }
    rule(:comparison_operation) { boolean_operation + (ws! + comparison_operator + ws! + boolean_operation)[1..] }
    rule(:boolean_operation) { postfix_expression + (ws! + boolean_operator + ws! + postfix_expression)[0..] }
    rule(:postfix_expression) { primary + (argument_list | property_accessor)[0..] }
    rule(:property_accessor) { str(".") + identifier }
    rule(:primary) { parens(expression) | type_of_expression | record_definition | literal | type_reference | reference | lambda | block }
    rule(:type_of_expression) { str("Type.of") + parens(expression) }
    rule(:type_reference) { str("Type") }
    rule(:argument_list) { parens(comma_separated(argument)) }
    rule(:argument) { expression }
    rule(:literal) { literal_null | literal_boolean | literal_string | literal_i64 }
    rule(:reference) { identifier }
    rule(:lambda) { lambda_op + parameter_list + ws? + block }
    rule(:parameter_list) { parens(comma_separated(parameter, allow_trailing: false)) }
    rule(:parameter) { identifier }
    rule(:block) { braces(statement_list) }
    rule(:record_definition) { str("Record") + parens(comma_separated(type_declaration, allow_trailing: false)) }

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
    terminal(:computed_property_id) { COMPUTED_PROPERTY_ID }
    terminal(:identifier) { Regexp.union(ALPHA_IDENTIFIER, BOOLEAN_OPERATOR, COMPARISON_OPERATOR) }

    # Operators
    terminal(:comparison_operator) { COMPARISON_OPERATOR }
    terminal(:boolean_operator) { BOOLEAN_OPERATOR }
    terminal(:lambda_op) { "λ" }
    terminal(:define_op) { ":=" }

    # Literals
    rule(:literal_null) { str("NULL") }
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
