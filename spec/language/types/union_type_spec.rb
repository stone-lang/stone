require "stone"
require "stone/scope"


RSpec.describe "Union Types" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "parsing simple union types" do
    it "parses simple union type annotation" do
      code = <<~STONE
        x :: Int | String
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses union with whitespace around pipe" do
      code = <<~STONE
        x :: Int|String
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses multi-alternative union" do
      code = <<~STONE
        x :: Int | String | Bool
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses nullable type" do
      code = <<~STONE
        x :: Int | Null
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses nullable type with NULL value" do
      code = <<~STONE
        x :: Int | Null
        x := NULL
        x
      STONE
      expect(Stone.eval(code)).to be_nil
    end
  end

  describe "type declaration storage" do
    it "stores union type declaration as Stone::Type" do
      code = <<~STONE
        x :: Int | String
        x := 42
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl).to be_a(Stone::Type)
      expect(decl.union?).to be true
    end

    it "stores union alternatives in declaration" do
      code = <<~STONE
        x :: Int | String
        x := 42
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl.alternatives.map(&:name)).to contain_exactly("Int", "String")
    end

    it "stores union type name correctly" do
      code = <<~STONE
        x :: Int | String
        x := 42
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl.to_s).to eq("Int | String")
    end

    it "stores nullable union type" do
      code = <<~STONE
        x :: Int | Null
        x := 42
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl.nullable?).to be true
    end
  end

  describe "in record fields" do
    # NOTE: These tests are pending because they require runtime union type support.
    # Union types in record fields need LLVM type representation and value handling
    # which is beyond phase 1 (parsing + type annotation storage).

    it "allows nullable field with non-null value", pending: "requires runtime union support" do
      code = <<~STONE
        Box := Record(value :: Int | Null)
        b := Box(42)
        b.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows nullable field with NULL value", pending: "requires runtime union support" do
      code = <<~STONE
        Box := Record(value :: Int | Null)
        b := Box(NULL)
        b.value
      STONE
      expect(Stone.eval(code)).to be_nil
    end

    it "allows multiple union-typed fields", pending: "requires runtime union support" do
      code = <<~STONE
        Container := Record(a :: Int | Null, b :: String | Null)
        c := Container(42, NULL)
        c.a
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows recursive type with NULL terminator", pending: "requires runtime union support" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList | Null)
        list := IntList(1, IntList(2, NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq(2)
    end
  end

  describe "in function signatures" do
    it "allows union in return type" do
      code = <<~STONE
        maybeDouble :: (Int) -> (Int | Null)
        maybeDouble := λ(x) { sum(x, x) }
        maybeDouble(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows union in parameter type" do
      code = <<~STONE
        process :: (Int | Null) -> Int
        process := λ(x) { 42 }
        process(NULL)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "stores function type with union return type" do
      code = <<~STONE
        f :: (Int) -> (Int | Null)
        f := λ(x) { x }
        42
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("f")
      expect(decl.function?).to be true
      expect(decl.return_type.union?).to be true
    end

    it "stores function type with union parameter type" do
      code = <<~STONE
        f :: (Int | Null) -> Int
        f := λ(x) { 42 }
        42
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("f")
      expect(decl.function?).to be true
      expect(decl.param_types.first.union?).to be true
    end
  end

  describe "flattening and deduplication" do
    it "flattens nested unions in annotations" do
      code = <<~STONE
        x :: (Int | String) | Bool
        x := TRUE
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl.alternatives.map(&:name)).to contain_exactly("Int", "String", "Bool")
    end

    it "deduplicates types in union (normalizing single-element to the type itself)" do
      code = <<~STONE
        x :: Int | Int
        x := 42
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("x")
      expect(decl.union?).to be false
      expect(decl.name).to eq("Int")
    end
  end

  describe "precedence" do
    it "union has lower precedence than function arrow (return type)" do
      code = <<~STONE
        f :: (Int) -> Int | Null
        f := λ(x) { x }
        42
      STONE
      _result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("f")
      expect(decl.function?).to be true
      expect(decl.return_type.union?).to be true
      expect(decl.return_type.to_s).to eq("Int | Null")
    end
  end

end
