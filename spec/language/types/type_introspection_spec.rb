require "stone"


RSpec.describe "Type introspection" do

  describe "record?" do
    it "returns TRUE for record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).record?
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns FALSE for Int" do
      expect(Stone.eval("Type.of(42).record?")).to be false
    end

    it "returns FALSE for Bool" do
      expect(Stone.eval("Type.of(TRUE).record?")).to be false
    end

    it "returns FALSE for String" do
      expect(Stone.eval('Type.of("hello").record?')).to be false
    end

    it "returns FALSE for Null" do
      expect(Stone.eval("Type.of(NULL).record?")).to be false
    end

    it "returns FALSE for Type" do
      expect(Stone.eval("Type.of(Type).record?")).to be false
    end
  end

  describe "primitive?" do
    it "returns TRUE for Int" do
      expect(Stone.eval("Type.of(42).primitive?")).to be true
    end

    it "returns TRUE for Bool" do
      expect(Stone.eval("Type.of(TRUE).primitive?")).to be true
    end

    it "returns TRUE for String" do
      expect(Stone.eval('Type.of("hello").primitive?')).to be true
    end

    it "returns TRUE for Null" do
      expect(Stone.eval("Type.of(NULL).primitive?")).to be true
    end

    it "returns FALSE for record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).primitive?
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns FALSE for Type (metatype)" do
      expect(Stone.eval("Type.of(Type).primitive?")).to be false
    end
  end

  describe "fields" do
    it "returns field list for record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        fields := Type.of(p).fields
        fields.first.name
      STONE
      expect(Stone.eval(code)).to eq("x")
    end

    it "returns field type information" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        fields := Type.of(p).fields
        fields.first.type.as_String
      STONE
      expect(Stone.eval(code)).to eq("Int")
    end

    it "supports traversing to next field" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        fields := Type.of(p).fields
        fields.rest.first.name
      STONE
      expect(Stone.eval(code)).to eq("y")
    end

    it "returns NULL for rest of last field" do
      code = <<~STONE
        Point := Record(x :: Int)
        p := Point(1)
        fields := Type.of(p).fields
        fields.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns NULL fields for primitive types" do
      expect(Stone.eval("Type.of(42).fields == NULL")).to be true
    end

    it "returns NULL fields for Type" do
      expect(Stone.eval("Type.of(Type).fields == NULL")).to be true
    end
  end

  describe "size" do
    it "returns 8 for Int (64-bit)" do
      expect(Stone.eval("Type.of(42).size")).to eq(8)
    end

    it "returns 1 for Bool (1-bit, rounded to byte)" do
      # NOTE: Bool is i1 in LLVM but we report byte size
      expect(Stone.eval("Type.of(TRUE).size")).to eq(1)
    end

    it "returns 8 for String (pointer size)" do
      expect(Stone.eval('Type.of("hello").size')).to eq(8)
    end

    it "returns correct size for record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).size
      STONE
      # Two i64 fields = 16 bytes
      expect(Stone.eval(code)).to eq(16)
    end
  end

  describe "kind" do
    # Kind values: 0=primitive, 1=record, 2=union, 3=function, 4=type
    it "returns 0 for primitives" do
      expect(Stone.eval("Type.of(42).kind")).to eq(0)
      expect(Stone.eval("Type.of(TRUE).kind")).to eq(0)
      expect(Stone.eval('Type.of("hello").kind')).to eq(0)
      expect(Stone.eval("Type.of(NULL).kind")).to eq(0)
    end

    it "returns 1 for record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).kind
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "returns 4 for Type" do
      expect(Stone.eval("Type.of(Type).kind")).to eq(4)
    end
  end

end
