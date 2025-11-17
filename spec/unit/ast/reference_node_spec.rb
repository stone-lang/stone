require "stone/ast/reference"

RSpec.describe Stone::AST::Reference do

  describe "#initialize" do
    it "stores the identifier name" do
      node = described_class.new("ZERO")
      expect(node.identifier).to eq("ZERO")
    end
  end

  describe "#to_s" do
    it "returns the identifier name" do
      node = described_class.new("ZERO")
      expect(node.to_s).to eq("ZERO")
    end
  end

end
