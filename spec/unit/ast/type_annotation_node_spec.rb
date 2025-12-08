require "stone/ast/type_annotation"

RSpec.describe Stone::AST::TypeAnnotation do

  describe "#initialize" do
    it "stores the type name" do
      node = described_class.new("Integer")
      expect(node.type_name).to eq("Integer")
    end

    it "stores different type names" do
      node = described_class.new("String")
      expect(node.type_name).to eq("String")
    end

    it "stores custom type names" do
      node = described_class.new("CustomType")
      expect(node.type_name).to eq("CustomType")
    end
  end

  describe "#to_s" do
    it "returns the type name" do
      node = described_class.new("Integer")
      expect(node.to_s).to eq("Integer")
    end

    it "returns different type names" do
      node = described_class.new("Boolean")
      expect(node.to_s).to eq("Boolean")
    end
  end

  describe "#name" do
    it "has the name :type_annotation" do
      node = described_class.new("Integer")
      expect(node.name).to eq(:type_annotation)
    end
  end

end
