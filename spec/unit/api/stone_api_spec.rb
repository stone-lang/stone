require "stone"

RSpec.describe "Stone API" do

  describe ".parse" do
    it "parses source code without evaluation" do
      parse_tree = Stone.parse("99")
      expect(parse_tree).to be_a(Grammy::ParseTree)
    end
  end

  describe ".transform" do
    it "transforms parse tree to AST" do
      parse_tree = Stone.parse("99")
      ast = Stone.transform(parse_tree)
      expect(ast).to be_a(Stone::AST)
    end
  end

  describe ".compile" do
    it "compiles source code to AST" do
      ast = Stone.compile("99")
      expect(ast).to be_a(Stone::AST)
    end
  end

  describe ".eval" do
    it "evaluates source code and returns result" do
      result = Stone.eval("42")
      expect(result).to eq(42)
    end
  end

end
