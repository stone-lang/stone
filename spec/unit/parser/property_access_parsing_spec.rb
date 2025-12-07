require "stone/grammar"

RSpec.describe "Property Access Parsing" do

  describe "simple property access" do
    it "parses property access on integer literal" do
      expect("42.positive?").to parse_as(:postfix_expression)
    end

    it "parses property access on boolean literal" do
      expect("TRUE.not").to parse_as(:postfix_expression)
    end

    it "parses property access on string literal" do
      expect('"hello".byte_count').to parse_as(:postfix_expression)
    end

    it "parses property access on reference" do
      expect("x.zero?").to parse_as(:postfix_expression)
    end

    it "parses property access on parenthesized expression" do
      expect("(42).positive?").to parse_as(:postfix_expression)
    end
  end

  describe "chained property access" do
    it "parses double-chained property access" do
      expect("TRUE.not.not").to parse_as(:postfix_expression)
    end

    it "parses triple-chained property access" do
      expect("x.positive?.not.not").to parse_as(:postfix_expression)
    end
  end

  describe "property access in expressions" do
    it "parses property access as function argument" do
      expect("sum(5.positive?, 3)").to parse_as(:postfix_expression)
    end

    it "parses property access on function call result" do
      expect("sum(5, 3).positive?").to parse_as(:postfix_expression)
    end
  end

  describe "distinguishing from other expressions" do
    it "parses identifier without dot as simple postfix (not property access)" do
      expect("x").to parse_as(:postfix_expression)
    end

    it "parses identifiers that look like properties but aren't" do
      expect("xpositive").to parse_as(:postfix_expression)  # Just a reference, no properties
    end
  end

end
