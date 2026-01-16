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
    describe "nullable fields (Int | Null)" do
      it "allows nullable field with non-null value" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(42)
          b.value
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      # NOTE: NULL returns 0 (the payload) because runtime type checking is needed
      # to distinguish NULL from Int(0). Future work: pattern matching or Type.of() check.
      it "allows nullable field with NULL value", pending: "requires runtime NULL detection" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(NULL)
          b.value
        STONE
        expect(Stone.eval(code)).to be_nil
      end

      it "allows multiple union-typed fields" do
        code = <<~STONE
          Container := Record(a :: Int | Null, b :: String | Null)
          c := Container(42, NULL)
          c.a
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      # NOTE: Chained property access on union fields requires runtime type dispatch.
      # The union payload (record pointer as i64) can't be directly accessed.
      # Future work: pattern matching or type-aware property access.
      it "allows recursive type with NULL terminator", pending: "requires runtime type dispatch for chained access" do
        code = <<~STONE
          IntList := Record(first :: Int, rest :: IntList | Null)
          list := IntList(1, IntList(2, NULL))
          list.rest.first
        STONE
        expect(Stone.eval(code)).to eq(2)
      end
    end

    describe "general union fields (Int | String)" do
      it "allows Int | String field with Int value" do
        code = <<~STONE
          Box := Record(value :: Int | String)
          b := Box(42)
          b.value
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      # NOTE: String payload is stored as i64 (pointer). Ruby-side needs to know
      # this is a string to read it correctly. Future work: runtime type dispatch.
      it "allows Int | String field with String value", pending: "requires runtime type dispatch for string conversion" do
        code = <<~STONE
          Box := Record(value :: Int | String)
          b := Box("hello")
          b.value
        STONE
        expect(Stone.eval(code)).to eq("hello")
      end
    end

    describe "Type.of() on union fields" do
      it "returns Int type for Int value in union field" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(42)
          Type.of(b.value).as_String
        STONE
        expect(Stone.eval(code)).to eq("Int")
      end

      it "returns Null type for NULL value in union field" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(NULL)
          Type.of(b.value).as_String
        STONE
        expect(Stone.eval(code)).to eq("Null")
      end

      it "returns String type for String value in Int|String field" do
        code = <<~STONE
          Box := Record(value :: Int | String)
          b := Box("hello")
          Type.of(b.value).as_String
        STONE
        expect(Stone.eval(code)).to eq("String")
      end
    end

    describe "field access in expressions" do
      it "allows using extracted Int value in arithmetic" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(42)
          sum(b.value, 1)
        STONE
        expect(Stone.eval(code)).to eq(43)
      end
    end

    describe "nested records with union types" do
      # NOTE: Accessing properties on union field results requires runtime type dispatch.
      # The payload (record pointer as i64) can't be directly accessed as a record.
      # Future work: pattern matching or type-aware property access.
      it "allows Record field with union type", pending: "requires runtime type dispatch for record access" do
        code = <<~STONE
          Inner := Record(x :: Int)
          Outer := Record(inner :: Inner | Null)
          i := Inner(42)
          o := Outer(i)
          o.inner.x
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      it "allows union of record types", pending: "requires runtime type dispatch for record access" do
        code = <<~STONE
          Circle := Record(radius :: Int)
          Square := Record(side :: Int)
          Container := Record(shape :: Circle | Square)
          c := Circle(10)
          box := Container(c)
          box.shape.radius
        STONE
        expect(Stone.eval(code)).to eq(10)
      end
    end

    describe "Bool in union fields" do
      # NOTE: Bool payload is zero-extended to i64. Ruby-side needs runtime type info
      # to know to interpret it as boolean. Returns 1/0 instead of true/false/nil.
      it "allows Bool | Null field with Bool value", pending: "requires runtime type dispatch for boolean conversion" do
        code = <<~STONE
          MaybeBool := Record(value :: Bool | Null)
          b := MaybeBool(TRUE)
          b.value
        STONE
        expect(Stone.eval(code)).to be true
      end

      it "allows Bool | Null field with NULL value", pending: "requires runtime NULL detection" do
        code = <<~STONE
          MaybeBool := Record(value :: Bool | Null)
          b := MaybeBool(NULL)
          b.value
        STONE
        expect(Stone.eval(code)).to be_nil
      end
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
