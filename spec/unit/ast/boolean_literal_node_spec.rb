require "stone/ast/boolean_literal"
require "stone/types"

RSpec.describe Stone::AST::BooleanLiteral do

  describe "constants" do
    it "defines TRUE as 1" do
      expect(Stone::AST::BooleanLiteral::TRUE).to eq(1)
    end

    it "defines FALSE as 0" do
      expect(Stone::AST::BooleanLiteral::FALSE).to eq(0)
    end
  end

  describe "#initialize" do
    it "stores TRUE value as 1" do
      literal = Stone::AST::BooleanLiteral.new("TRUE")
      expect(literal.value).to eq(Stone::AST::BooleanLiteral::TRUE)
      expect(literal.value).to eq(1)
    end

    it "stores FALSE value as 0" do
      literal = Stone::AST::BooleanLiteral.new("FALSE")
      expect(literal.value).to eq(Stone::AST::BooleanLiteral::FALSE)
      expect(literal.value).to eq(0)
    end

    it "sets name to :boolean_literal" do
      literal = Stone::AST::BooleanLiteral.new("TRUE")
      expect(literal.name).to eq(:boolean_literal)
    end

    it "raises error for invalid boolean value" do
      expect { Stone::AST::BooleanLiteral.new("invalid") }.to raise_error(RuntimeError, /expected TRUE or FALSE/)
    end

    it "is case-sensitive (lowercase fails)" do
      expect { Stone::AST::BooleanLiteral.new("true") }.to raise_error(RuntimeError, /expected TRUE or FALSE/)
      expect { Stone::AST::BooleanLiteral.new("false") }.to raise_error(RuntimeError, /expected TRUE or FALSE/)
    end
  end

  describe ".parse" do
    it "parses TRUE string" do
      literal = Stone::AST::BooleanLiteral.parse("TRUE", nil)
      expect(literal.value).to eq(Stone::AST::BooleanLiteral::TRUE)
    end

    it "parses FALSE string" do
      literal = Stone::AST::BooleanLiteral.parse("FALSE", nil)
      expect(literal.value).to eq(Stone::AST::BooleanLiteral::FALSE)
    end
  end

  describe "#type" do
    it "returns Stone::Type::Bool" do
      literal = Stone::AST::BooleanLiteral.new("TRUE")
      expect(literal.type).to eq(Stone::Type::Bool)
    end
  end

end
