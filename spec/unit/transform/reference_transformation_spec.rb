require "stone/grammar"
require "stone/transform"
require "stone/ast/reference"

RSpec.describe "Reference Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "transforming references" do
    it "transforms ZERO to Reference AST node" do
      parse_tree = Stone::Grammar.parse("ZERO")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      expect(ast.children.first).to be_a(Stone::AST::Reference)
      expect(ast.children.first.identifier).to eq("ZERO")
    end

    it "transforms ONE to Reference AST node" do
      parse_tree = Stone::Grammar.parse("ONE")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      expect(ast.children.first).to be_a(Stone::AST::Reference)
      expect(ast.children.first.identifier).to eq("ONE")
    end

    it "transforms any identifier to Reference AST node" do
      parse_tree = Stone::Grammar.parse("foo")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      expect(ast.children.first).to be_a(Stone::AST::Reference)
      expect(ast.children.first.identifier).to eq("foo")
    end
  end

  describe "preserving identifier names" do
    it "preserves the exact identifier from source" do
      parse_tree = Stone::Grammar.parse("myConstant")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first.identifier).to eq("myConstant")
    end
  end

end
