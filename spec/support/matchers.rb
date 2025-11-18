# Custom RSpec matchers for Stone parser testing

# Matcher for testing that input parses as a specific grammar rule
#
# Usage:
#   expect("foo").to parse_as(:reference)
#   expect("42").to parse_as(:literal_i64)
#   expect("!@#").not_to parse_as(:reference)
RSpec::Matchers.define :parse_as do |expected_rule|
  match do |input|
    result = Stone::Grammar.parse(input)
    @actual_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == expected_rule.to_sym }
    !@actual_node.nil?
  rescue Grammy::ParseError => e
    @parse_error = e
    false
  end

  failure_message do
    if @parse_error
      "expected '#{actual}' to parse as :#{expected_rule}, but parsing failed with: #{@parse_error.message}"
    else
      available_rules = begin
        result = Stone::Grammar.parse(actual)
        result.select { |node| node.is_a?(Grammy::ParseTree) }.map(&:name).join(", ")
      rescue StandardError
        "none"
      end
      "expected '#{actual}' to parse as :#{expected_rule}, but found rules: #{available_rules}"
    end
  end

  failure_message_when_negated do
    "expected '#{actual}' not to parse as :#{expected_rule}, but it did"
  end

  description do
    "parse as :#{expected_rule}"
  end
end
