require "stone/ast/type_declaration"
require "stone/ast/type_annotation"

RSpec.describe Stone::AST::TypeDeclaration do

  describe "#initialize" do
    it "stores the identifier and type annotation" do
      type_annotation = Stone::AST::TypeAnnotation.new("Integer")
      node = described_class.new("x", type_annotation)
      expect(node.identifier).to eq("x")
      expect(node.type_annotation).to eq(type_annotation)
    end

    it "works with different identifiers" do
      type_annotation = Stone::AST::TypeAnnotation.new("String")
      node = described_class.new("myVar", type_annotation)
      expect(node.identifier).to eq("myVar")
      expect(node.type_annotation.type_name).to eq("String")
    end
  end

  describe "#to_s" do
    it "returns formatted type declaration" do
      type_annotation = Stone::AST::TypeAnnotation.new("Integer")
      node = described_class.new("x", type_annotation)
      expect(node.to_s).to eq("x :: Integer")
    end

    it "formats different types correctly" do
      type_annotation = Stone::AST::TypeAnnotation.new("Boolean")
      node = described_class.new("flag", type_annotation)
      expect(node.to_s).to eq("flag :: Boolean")
    end

    it "formats custom types correctly" do
      type_annotation = Stone::AST::TypeAnnotation.new("CustomType")
      node = described_class.new("value", type_annotation)
      expect(node.to_s).to eq("value :: CustomType")
    end
  end

  describe "#name" do
    it "has the name :type_declaration" do
      type_annotation = Stone::AST::TypeAnnotation.new("Integer")
      node = described_class.new("x", type_annotation)
      expect(node.name).to eq(:type_declaration)
    end
  end

end
