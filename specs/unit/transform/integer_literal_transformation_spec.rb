require "stone/transform"
require "stone/grammar"

RSpec.describe "Integer Literal Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "transforming parse tree to AST" do
    it "transforms positive integer" do
      parse_tree = Stone::Grammar.parse("42")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(42)
    end

    it "transforms negative integer" do
      parse_tree = Stone::Grammar.parse("-17")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(-17)
    end

    it "transforms zero" do
      parse_tree = Stone::Grammar.parse("0")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(0)
    end
  end

end
