require "stone/grammar"

RSpec.describe "Boolean Literal Parsing" do

  describe "TRUE literal" do
    it "parses TRUE" do
      expect("TRUE").to parse_as(:literal_boolean)
    end

    it "parses TRUE as part of a program" do
      result = Stone::Grammar.parse("TRUE")
      statement_list = result.find_child(:statement_list)
      expect(statement_list).not_to be_empty
      expect(statement_list.children.first).not_to be_nil
    end
  end

  describe "FALSE literal" do
    it "parses FALSE" do
      expect("FALSE").to parse_as(:literal_boolean)
    end

    it "parses FALSE as part of a program" do
      result = Stone::Grammar.parse("FALSE")
      statement_list = result.find_child(:statement_list)
      expect(statement_list).not_to be_empty
      expect(statement_list.children.first).not_to be_nil
    end
  end



end
