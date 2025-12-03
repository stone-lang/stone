require "stone/ast/boolean_literal"

RSpec.describe Stone::AST::BooleanLiteral do

  describe "#initialize" do
    it "stores TRUE value as 1" do
      literal = Stone::AST::BooleanLiteral.new("TRUE")
      expect(literal.value).to eq(Stone::Type::Bool::TRUE)
      expect(literal.value).to eq(1)
    end

    it "stores FALSE value as 0" do
      literal = Stone::AST::BooleanLiteral.new("FALSE")
      expect(literal.value).to eq(Stone::Type::Bool::FALSE)
      expect(literal.value).to eq(0)
    end

    it "sets name to :boolean_literal" do
      literal = Stone::AST::BooleanLiteral.new("TRUE")
      expect(literal.name).to eq(:boolean_literal)
    end
  end

  describe ".parse" do
    it "parses TRUE string" do
      literal = Stone::AST::BooleanLiteral.parse("TRUE", nil)
      expect(literal.value).to eq(Stone::Type::Bool::TRUE)
    end

    it "parses FALSE string" do
      literal = Stone::AST::BooleanLiteral.parse("FALSE", nil)
      expect(literal.value).to eq(Stone::Type::Bool::FALSE)
    end
  end

end
