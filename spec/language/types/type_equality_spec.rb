require "stone"


RSpec.describe "Type equality" do

  describe "primitive type equality" do
    it "returns TRUE when comparing same Int types" do
      expect(Stone.eval("Type.of(42) == Type.of(1)")).to be true
    end

    it "returns TRUE when comparing same Bool types" do
      expect(Stone.eval("Type.of(TRUE) == Type.of(FALSE)")).to be true
    end

    it "returns TRUE when comparing same String types" do
      code = <<~STONE
        Type.of("hello") == Type.of("world")
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns TRUE when comparing same Null types" do
      expect(Stone.eval("Type.of(NULL) == Type.of(NULL)")).to be true
    end

    it "returns FALSE when comparing different types" do
      expect(Stone.eval("Type.of(42) == Type.of(TRUE)")).to be false
    end

    it "returns FALSE when comparing Int and String" do
      code = <<~STONE
        Type.of(42) == Type.of("hello")
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns FALSE when comparing Int and Null" do
      expect(Stone.eval("Type.of(42) == Type.of(NULL)")).to be false
    end
  end

  describe "type inequality" do
    it "returns FALSE when comparing same types with !=" do
      expect(Stone.eval("Type.of(42) != Type.of(1)")).to be false
    end

    it "returns TRUE when comparing different types with !=" do
      expect(Stone.eval("Type.of(42) != Type.of(TRUE)")).to be true
    end

    it "works with Unicode inequality operator" do
      expect(Stone.eval("Type.of(42) ≠ Type.of(TRUE)")).to be true
    end
  end

  describe "record type equality" do
    it "returns TRUE for same record type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p1 := Point(1, 2)
        p2 := Point(3, 4)
        Type.of(p1) == Type.of(p2)
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns FALSE for different record types" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Size := Record(width :: Int, height :: Int)
        p := Point(1, 2)
        s := Size(10, 20)
        Type.of(p) == Type.of(s)
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns FALSE when comparing record type with primitive type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p) == Type.of(42)
      STONE
      expect(Stone.eval(code)).to be false
    end
  end

  describe "metatype equality" do
    it "Type.of(Type.of(x)) equals Type.of(Type.of(y))" do
      code = <<~STONE
        Type.of(Type.of(42)) == Type.of(Type.of(TRUE))
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "Type type equals itself" do
      expect(Stone.eval("Type.of(Type) == Type.of(Type)")).to be true
    end
  end

end
