require "stone/ast/integer_literal"
require "stone/types"

RSpec.describe Stone::AST::IntegerLiteral do

  describe "#initialize" do
    it "stores the integer value" do
      literal = Stone::AST::IntegerLiteral.new(42)
      expect(literal.value).to eq(42)
    end
  end

  describe ".in_range?" do
    it "returns true for values within i64 range" do
      expect(Stone::AST::IntegerLiteral.in_range?(0)).to be true
      expect(Stone::AST::IntegerLiteral.in_range?(100)).to be true
      expect(Stone::AST::IntegerLiteral.in_range?(-100)).to be true
    end

    it "returns true for i64 max value" do
      max = 2**63 - 1
      expect(Stone::AST::IntegerLiteral.in_range?(max)).to be true
    end

    it "returns true for i64 min value" do
      min = -(2**63)
      expect(Stone::AST::IntegerLiteral.in_range?(min)).to be true
    end

    it "returns false for values above i64 max" do
      expect(Stone::AST::IntegerLiteral.in_range?(2**63)).to be false
    end

    it "returns false for values below i64 min" do
      expect(Stone::AST::IntegerLiteral.in_range?(-(2**63) - 1)).to be false
    end
  end

  describe ".in_range? uses Stone::Type::Int bounds" do
    it "validates against Stone::Type::Int.min" do
      expect(Stone::AST::IntegerLiteral.in_range?(Stone::Type::Int.min)).to be true
      expect(Stone::AST::IntegerLiteral.in_range?(Stone::Type::Int.min - 1)).to be false
    end

    it "validates against Stone::Type::Int.max" do
      expect(Stone::AST::IntegerLiteral.in_range?(Stone::Type::Int.max)).to be true
      expect(Stone::AST::IntegerLiteral.in_range?(Stone::Type::Int.max + 1)).to be false
    end
  end

  describe "#type" do
    it "returns Stone::Type::Int" do
      literal = Stone::AST::IntegerLiteral.new(42)
      expect(literal.type).to eq(Stone::Type::Int)
    end
  end

end
