require "stone/grammar"

RSpec.describe "Integer Literal Parsing" do

  describe "decimal integers" do
    it "parses positive integers" do
      result = Stone::Grammar.parse("42")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end

    it "parses negative integers" do
      result = Stone::Grammar.parse("-17")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end

    it "parses zero" do
      result = Stone::Grammar.parse("0")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end
  end

  describe "binary integers" do
    it "parses binary integers" do
      result = Stone::Grammar.parse("0b1010")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("0b1010")
    end

    it "parses negative binary integers" do
      result = Stone::Grammar.parse("-0b101")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("-0b101")
    end

    it "parses positive signed binary integers" do
      result = Stone::Grammar.parse("+0b101")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("+0b101")
    end
  end

  describe "octal integers" do
    it "parses octal integers" do
      result = Stone::Grammar.parse("0o777")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("0o777")
    end

    it "parses negative octal integers" do
      result = Stone::Grammar.parse("-0o77")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("-0o77")
    end

    it "parses positive signed octal integers" do
      result = Stone::Grammar.parse("+0o123")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("+0o123")
    end
  end

  describe "hexadecimal integers" do
    it "parses hex integers" do
      result = Stone::Grammar.parse("0xff")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("0xff")
    end

    it "parses hex integers with mixed case digits" do
      result = Stone::Grammar.parse("0xDeAdBeEf")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("0xDeAdBeEf")
    end

    it "parses negative hex integers" do
      result = Stone::Grammar.parse("-0xff")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("-0xff")
    end

    it "parses positive signed hex integers" do
      result = Stone::Grammar.parse("+0xABC")
      literal_node = result.find { |node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
      expect(literal_node.children.first.text).to eq("+0xABC")
    end
  end

  describe "edge cases" do
    it "parses empty input as empty program" do
      result = Stone::Grammar.parse("")
      expect(result).to be_empty
    end

    it "raises ParseError for non-numeric input" do
      expect { Stone::Grammar.parse("abc") }.to raise_error(Grammy::ParseError)
    end
  end

end
# rubocop:enable RSpec/DescribeClass
