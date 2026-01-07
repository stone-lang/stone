require "stone/grammar"

RSpec.describe "NULL Literal Parsing" do

  describe "NULL literal" do
    it "parses NULL" do
      expect("NULL").to parse_as(:literal_null)
    end

    it "parses NULL as part of a program" do
      result = Stone::Grammar.parse("NULL")
      statement_list = result.find_child(:statement_list)
      expect(statement_list).not_to be_empty
      expect(statement_list.children.first).not_to be_nil
    end
  end

end
