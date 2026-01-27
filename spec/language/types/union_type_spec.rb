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

      it "allows nullable field with NULL value" do
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

      # Chained access on union fields requires runtime type dispatch to extract
      # the underlying record from the union before accessing its properties.
      it "allows recursive type with NULL terminator", pending: "requires chained property access on union fields" do
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

      # Multi-type unions (without Null) require runtime type checking to know
      # which alternative was stored and how to interpret the payload.
      it "allows Int | String field with String value", pending: "requires runtime type dispatch for multi-type unions" do
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
      # Chained access on union fields requires runtime type dispatch to extract
      # the underlying record from the union before accessing its properties.
      it "allows Record field with union type", pending: "requires chained property access on union fields" do
        code = <<~STONE
          Inner := Record(x :: Int)
          Outer := Record(inner :: Inner | Null)
          i := Inner(42)
          o := Outer(i)
          o.inner.x
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      # Chained access on union fields requires runtime type dispatch.
      it "allows union of record types", pending: "requires chained property access on union fields" do
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
      it "allows Bool | Null field with Bool value" do
        code = <<~STONE
          MaybeBool := Record(value :: Bool | Null)
          b := MaybeBool(TRUE)
          b.value
        STONE
        expect(Stone.eval(code)).to be true
      end

      it "allows Bool | Null field with NULL value" do
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

  describe "variable-sized union payloads" do
    describe "payload storage without ptr2int" do
      it "stores and retrieves Int values correctly" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(42)
          b.value
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      it "stores and retrieves String pointers correctly" do
        code = <<~STONE
          Box := Record(value :: String | Null)
          b := Box("hello")
          b.value
        STONE
        expect(Stone.eval(code)).to eq("hello")
      end

      # Chained access on union fields requires runtime type dispatch.
      it "stores and retrieves record pointers correctly", pending: "requires chained property access on union fields" do
        code = <<~STONE
          Inner := Record(x :: Int)
          Outer := Record(value :: Inner | Null)
          o := Outer(Inner(42))
          o.value.x
        STONE
        expect(Stone.eval(code)).to eq(42)
      end
    end

    describe "type-aware payload extraction" do
      it "extracts Int from Int | String union" do
        code = <<~STONE
          Box := Record(value :: Int | String)
          b := Box(123)
          sum(b.value, 1)
        STONE
        expect(Stone.eval(code)).to eq(124)
      end

      # Multi-type unions require runtime type checking to distinguish alternatives.
      it "extracts String from Int | String union", pending: "requires runtime type dispatch for multi-type unions" do
        code = <<~STONE
          Box := Record(value :: Int | String)
          b := Box("world")
          b.value
        STONE
        expect(Stone.eval(code)).to eq("world")
      end

      # Multi-type unions require runtime type checking to distinguish alternatives.
      it "extracts Bool from Bool | Int union", pending: "requires runtime type dispatch for multi-type unions" do
        code = <<~STONE
          Box := Record(value :: Bool | Int)
          b := Box(TRUE)
          b.value
        STONE
        expect(Stone.eval(code)).to be true
      end
    end

    describe "NULL handling" do
      it "returns nil for NULL in Int | Null" do
        code = <<~STONE
          Box := Record(value :: Int | Null)
          b := Box(NULL)
          b.value
        STONE
        expect(Stone.eval(code)).to be_nil
      end

      it "returns nil for NULL in String | Null" do
        code = <<~STONE
          Box := Record(value :: String | Null)
          b := Box(NULL)
          b.value
        STONE
        expect(Stone.eval(code)).to be_nil
      end

      it "returns nil for NULL in Record | Null" do
        code = <<~STONE
          Inner := Record(x :: Int)
          Outer := Record(value :: Inner | Null)
          o := Outer(NULL)
          o.value
        STONE
        expect(Stone.eval(code)).to be_nil
      end
    end

    describe "chained access through union fields" do
      # Chained access on union fields requires runtime type dispatch to extract
      # the underlying record from the union before accessing its properties.
      it "accesses properties on record from union field", pending: "requires chained property access on union fields" do
        code = <<~STONE
          Point := Record(x :: Int, y :: Int)
          Box := Record(point :: Point | Null)
          b := Box(Point(10, 20))
          b.point.x
        STONE
        expect(Stone.eval(code)).to eq(10)
      end

      # Chained access on union fields requires runtime type dispatch.
      it "accesses second property on record from union field", pending: "requires chained property access on union fields" do
        code = <<~STONE
          Point := Record(x :: Int, y :: Int)
          Box := Record(point :: Point | Null)
          b := Box(Point(10, 20))
          b.point.y
        STONE
        expect(Stone.eval(code)).to eq(20)
      end
    end
  end

end
