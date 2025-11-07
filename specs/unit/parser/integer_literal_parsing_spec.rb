require "stone/grammar"

RSpec.describe "Integer Literal Parsing" do

  describe "decimal integers" do
    it "parses positive integers" do
      result = Stone::Grammar.parse("42")
      literal_node = result.find {|node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end

    it "parses negative integers" do
      result = Stone::Grammar.parse("-17")
      literal_node = result.find {|node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end

    it "parses zero" do
      result = Stone::Grammar.parse("0")
      literal_node = result.find {|node| node.is_a?(Grammy::ParseTree) && node.name == "literal_i64" }
      expect(literal_node).not_to be_nil
    end
  end

  describe "edge cases" do
    it "returns parse tree with nil for empty input" do
      result = Stone::Grammar.parse("")
      expect(result.children).to be_nil
    end

    it "returns parse tree with nil for invalid input" do
      result = Stone::Grammar.parse("abc")
      expect(result.children).to be_nil
    end
  end

end
