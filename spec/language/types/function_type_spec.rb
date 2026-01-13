require "stone"
require "stone/scope"

RSpec.describe "Function Type Syntax" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "parsing function types" do
    it "parses simple function type in signature" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { sum(x, x) }
        double(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses multi-parameter function type" do
      code = <<~STONE
        add :: (Int, Int) -> Int
        add := λ(x, y) { sum(x, y) }
        add(20, 22)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses zero-parameter function type" do
      code = <<~STONE
        answer :: () -> Int
        answer := λ() { 42 }
        answer()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "nested function types require explicit parentheses" do
    it "rejects unparenthesized nested function types" do
      code = "f :: (Int) -> (Int) -> Int"
      expect { Stone.parse(code) }.to raise_error(Grammy::ParseError)
    end

    it "accepts nested function type with explicit parens" do
      code = "f :: (Int) -> ((Int) -> Int)"
      expect { Stone.parse(code) }.not_to raise_error
    end

    it "accepts deeply nested function type" do
      code = "f :: (Int) -> ((Int) -> ((Int) -> Int))"
      expect { Stone.parse(code) }.not_to raise_error
    end

    it "accepts function taking function as parameter" do
      code = "f :: ((Int) -> Int) -> Int"
      expect { Stone.parse(code) }.not_to raise_error
    end
  end

  describe "type declaration storage" do
    it "stores simple type declarations as Stone::Type" do
      code = <<~STONE
        answer :: Int
        answer := 42
        answer
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(result).to eq(42)
      decl = scope.declared_type("answer")
      expect(decl).to be_a(Stone::Type)
      expect(decl.to_s).to eq("Int")
    end

    it "stores function type declarations as Stone::Type" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { sum(x, x) }
        double(21)
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("double")
      expect(decl).to be_a(Stone::Type)
      expect(decl.function?).to be true
      expect(decl.to_s).to eq("(Int) -> Int")
    end

    it "stores multi-parameter function type" do
      code = <<~STONE
        add :: (Int, Int) -> Int
        add := λ(x, y) { sum(x, y) }
        add(1, 2)
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("add")
      expect(decl.to_s).to eq("(Int, Int) -> Int")
    end

    it "stores zero-parameter function type" do
      code = <<~STONE
        getAnswer :: () -> Int
        getAnswer := λ() { 42 }
        getAnswer()
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("getAnswer")
      expect(decl.to_s).to eq("() -> Int")
    end

    it "stores curried function type with correct to_s" do
      code = <<~STONE
        add :: (Int) -> ((Int) -> Int)
        add := λ(x) { λ(y) { y } }
        42
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("add")
      expect(decl.to_s).to eq("(Int) -> ((Int) -> Int)")
      expect(decl.function?).to be true
      expect(decl.return_type.function?).to be true
    end
  end

end
