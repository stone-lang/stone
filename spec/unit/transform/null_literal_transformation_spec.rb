require "stone/transform"
require "stone/grammar"

RSpec.describe "NULL Literal Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "transforming parse tree to AST" do
    it "transforms NULL to NullLiteral" do
      parse_tree = Stone::Grammar.parse("NULL")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::NullLiteral)
    end

    it "sets correct node name" do
      parse_tree = Stone::Grammar.parse("NULL")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first.name).to eq(:null_literal)
    end
  end

  describe "NULL LLVM representation" do
    it "represents NULL as i64 value 0 in LLVM" do
      parse_tree = Stone::Grammar.parse("NULL")
      ast = transformer.transform(parse_tree)
      null_node = ast.children.first

      llvm_value = null_node.to_llir(nil, nil)
      expect(llvm_value.to_i).to eq(0)
    end
  end

  describe "multiple NULL literals" do
    it "transforms multiple NULL literals independently" do
      parse_tree = Stone::Grammar.parse("NULL\nNULL")
      ast = transformer.transform(parse_tree)

      expect(ast.children.count).to be >= 2
      expect(ast.children[0]).to be_a(Stone::AST::NullLiteral)
      expect(ast.children[1]).to be_a(Stone::AST::NullLiteral)
    end

    it "transforms mixed NULL and other literals" do
      parse_tree = Stone::Grammar.parse("NULL\n42")
      ast = transformer.transform(parse_tree)

      expect(ast.children.count).to be >= 2
      expect(ast.children[0]).to be_a(Stone::AST::NullLiteral)
      expect(ast.children[1]).to be_a(Stone::AST::IntegerLiteral)
    end
  end

end
