require "stone/grammar"
require "stone/transform"
require "stone/ast/property_access"


RSpec.describe "Property Access Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "simple property access transformation" do
    it "transforms property access on integer literal to PropertyAccess AST node" do
      parse_tree = Stone::Grammar.parse("42.positive?")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      property_access = ast.children.first
      expect(property_access).to be_a(Stone::AST::PropertyAccess)
      expect(property_access.receiver).to be_a(Stone::AST::IntegerLiteral)
      expect(property_access.property).to eq("positive?")
    end

    it "transforms property access on boolean literal to PropertyAccess AST node" do
      parse_tree = Stone::Grammar.parse("TRUE.not")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      property_access = ast.children.first
      expect(property_access).to be_a(Stone::AST::PropertyAccess)
      expect(property_access.receiver).to be_a(Stone::AST::BooleanLiteral)
      expect(property_access.property).to eq("not")
    end

    it "transforms property access on reference to PropertyAccess AST node" do
      parse_tree = Stone::Grammar.parse("x.zero?")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      property_access = ast.children.first
      expect(property_access).to be_a(Stone::AST::PropertyAccess)
      expect(property_access.receiver).to be_a(Stone::AST::Reference)
      expect(property_access.property).to eq("zero?")
    end
  end

  describe "chained property access transformation" do
    it "transforms double-chained properties to nested PropertyAccess nodes" do
      parse_tree = Stone::Grammar.parse("TRUE.not.not")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      outer = ast.children.first
      expect(outer).to be_a(Stone::AST::PropertyAccess)
      expect(outer.property).to eq("not")

      inner = outer.receiver
      expect(inner).to be_a(Stone::AST::PropertyAccess)
      expect(inner.property).to eq("not")
      expect(inner.receiver).to be_a(Stone::AST::BooleanLiteral)
    end

    it "transforms triple-chained properties correctly" do  # rubocop:disable RSpec/ExampleLength
      parse_tree = Stone::Grammar.parse("x.positive?.not.not")
      ast = transformer.transform(parse_tree)

      expect(ast).to be_a(Stone::AST::ProgramUnit)
      # Outermost: x.positive?.not.not
      outer = ast.children.first
      expect(outer).to be_a(Stone::AST::PropertyAccess)
      expect(outer.property).to eq("not")

      # Middle: x.positive?.not
      middle = outer.receiver
      expect(middle).to be_a(Stone::AST::PropertyAccess)
      expect(middle.property).to eq("not")

      # Inner: x.positive?
      inner = middle.receiver
      expect(inner).to be_a(Stone::AST::PropertyAccess)
      expect(inner.property).to eq("positive?")
      expect(inner.receiver).to be_a(Stone::AST::Reference)
    end
  end

  describe "preserving property names" do
    it "preserves property name exactly from source" do
      parse_tree = Stone::Grammar.parse("value.zero?")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first.property).to eq("zero?")
    end
  end

end
