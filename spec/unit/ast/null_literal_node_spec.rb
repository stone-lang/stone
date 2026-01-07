require "llvm/core"
require "stone/ast/null_literal"
require "stone/types"

RSpec.describe Stone::AST::NullLiteral do

  describe "#initialize" do
    it "sets name to :null_literal" do
      literal = Stone::AST::NullLiteral.new
      expect(literal.name).to eq(:null_literal)
    end
  end

  describe ".parse" do
    it "returns a NullLiteral instance" do
      literal = Stone::AST::NullLiteral.parse("NULL", nil)
      expect(literal).to be_a(Stone::AST::NullLiteral)
    end

    it "ignores the text parameter (grammar ensures only NULL reaches here)" do
      literal = Stone::AST::NullLiteral.parse("anything", nil)
      expect(literal).to be_a(Stone::AST::NullLiteral)
    end
  end

  describe "#type" do
    it "returns Stone::Type::Null" do
      literal = Stone::AST::NullLiteral.new
      expect(literal.type).to eq(Stone::Type::Null)
    end
  end

  describe "#to_s" do
    it "returns 'NULL'" do
      literal = Stone::AST::NullLiteral.new
      expect(literal.to_s).to eq("NULL")
    end
  end

  describe "#to_llir" do
    it "returns LLVM null pointer" do
      literal = Stone::AST::NullLiteral.new
      llvm_value = literal.to_llir(nil, nil)
      expect(llvm_value).to be_a(LLVM::Constant)
      expect(llvm_value.type.kind).to eq(:pointer)
      expect(llvm_value.null?).to be true
    end
  end

end
