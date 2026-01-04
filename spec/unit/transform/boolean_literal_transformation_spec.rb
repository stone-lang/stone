require "stone/transform"
require "stone/grammar"

RSpec.describe "Boolean Literal Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "transforming parse tree to AST" do
    it "transforms TRUE to BooleanLiteral with value 1" do
      parse_tree = Stone::Grammar.parse("TRUE")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children.first.value).to eq(Stone::AST::BooleanLiteral::TRUE)
      expect(ast.children.first.value).to eq(1)
    end

    it "transforms FALSE to BooleanLiteral with value 0" do
      parse_tree = Stone::Grammar.parse("FALSE")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children.first.value).to eq(Stone::AST::BooleanLiteral::FALSE)
      expect(ast.children.first.value).to eq(0)
    end

    it "sets correct node name" do
      parse_tree = Stone::Grammar.parse("TRUE")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first.name).to eq(:boolean_literal)
    end
  end

  describe "Boolean type representation" do
    it "represents TRUE as i1 value 1 in LLVM" do
      parse_tree = Stone::Grammar.parse("TRUE")
      ast = transformer.transform(parse_tree)
      boolean_node = ast.children.first

      expect(boolean_node.value).to eq(1)
    end

    it "represents FALSE as i1 value 0 in LLVM" do
      parse_tree = Stone::Grammar.parse("FALSE")
      ast = transformer.transform(parse_tree)
      boolean_node = ast.children.first

      expect(boolean_node.value).to eq(0)
    end
  end

  describe "multiple Boolean literals" do
    it "transforms multiple TRUE literals independently" do
      # NOTE: This test assumes the grammar supports multiple statements
      # If not yet supported, this test documents future behavior
      parse_tree = Stone::Grammar.parse("TRUE\nTRUE")
      ast = transformer.transform(parse_tree)

      expect(ast.children.count).to be >= 2
      expect(ast.children[0]).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children[1]).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children[0].value).to eq(1)
      expect(ast.children[1].value).to eq(1)
    end

    it "transforms mixed TRUE and FALSE literals" do
      parse_tree = Stone::Grammar.parse("TRUE\nFALSE")
      ast = transformer.transform(parse_tree)

      expect(ast.children.count).to be >= 2
      expect(ast.children[0]).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children[1]).to be_a(Stone::AST::BooleanLiteral)
      expect(ast.children[0].value).to eq(1)
      expect(ast.children[1].value).to eq(0)
    end
  end

end
