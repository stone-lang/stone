require "stone"


RSpec.describe "Type.of() special form" do

  describe "with literals" do
    it "returns Int type name for integer literals" do
      expect(Stone.eval("Type.of(42).as_String")).to eq("Int")
    end

    it "returns Bool type name for boolean literals" do
      expect(Stone.eval("Type.of(TRUE).as_String")).to eq("Bool")
    end

    it "returns String type name for string literals" do
      expect(Stone.eval('Type.of("hello").as_String')).to eq("String")
    end
  end

  describe "with expressions" do
    it "returns Bool for comparison results" do
      expect(Stone.eval("Type.of(5 < 3).as_String")).to eq("Bool")
    end

    it "returns Bool for property access returning Bool" do
      expect(Stone.eval("Type.of(42.positive?).as_String")).to eq("Bool")
    end
  end

  describe "with variables" do
    it "returns the type of a defined constant" do
      code = <<~STONE
        x := 42
        Type.of(x).as_String
      STONE
      expect(Stone.eval(code)).to eq("Int")
    end
  end

  describe "with record instances" do
    it "returns the record type name" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).as_String
      STONE
      expect(Stone.eval(code)).to eq("Point")
    end
  end

  describe "metatypes" do
    it "Type.of(Type.of(anything)) returns Type" do
      code = <<~STONE
        Type.of(Type.of(42)).as_String
      STONE
      expect(Stone.eval(code)).to eq("Type")
    end

    it "Type.of(Type) returns Type" do
      code = <<~STONE
        Type.of(Type).as_String
      STONE
      expect(Stone.eval(code)).to eq("Type")
    end

    it "Type.as_String returns 'Type'" do
      expect(Stone.eval("Type.as_String")).to eq("Type")
    end
  end

end
