require "stone/ast/integer_literal"

RSpec.describe Stone::AST::IntegerLiteral do

  describe "#to_llir" do
    it "generates correct value for positive integers" do
      literal = Stone::AST::IntegerLiteral.new(100)
      result = literal.to_llir(nil)
      expect(result.to_i).to eq(100)
    end

    it "generates correct value for negative integers" do
      literal = Stone::AST::IntegerLiteral.new(-50)
      result = literal.to_llir(nil)
      expect(result.to_i).to eq(-50)
    end

    it "generates correct value for zero" do
      literal = Stone::AST::IntegerLiteral.new(0)
      result = literal.to_llir(nil)
      expect(result.to_i).to eq(0)
    end
  end

end
