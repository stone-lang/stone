require "stone"


RSpec.describe "Generic Types" do

  describe "type-level lambda definitions" do
    it "allows defining a generic type as a type-level function" do
      code = <<~STONE
        Box :: (Type) -> Type
        Box := λ(T) { Record(value :: T) }
        Box
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "allows defining a generic type with two type parameters" do
      code = <<~STONE
        Pair :: (Type, Type) -> Type
        Pair := λ(KeyType, ValueType) { Record(key :: KeyType, value :: ValueType) }
        Pair
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "generic type instantiation" do
    it "allows instantiating a generic type via function application" do
      code = <<~STONE
        Box :: (Type) -> Type
        Box := λ(T) { Record(value :: T) }
        IntBox := Box(Int)
        IntBox
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "can create instances of instantiated generic types" do
      code = <<~STONE
        Box :: (Type) -> Type
        Box := λ(T) { Record(value :: T) }
        IntBox := Box(Int)
        b := IntBox(42)
        b.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "supports multiple instantiations of same generic type" do
      code = <<~STONE
        Box :: (Type) -> Type
        Box := λ(T) { Record(value :: T) }
        IntBox := Box(Int)
        StringBox := Box(String)
        ib := IntBox(42)
        sb := StringBox("hello")
        sb.value
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end

    it "can access all fields of multi-parameter type" do
      code = <<~STONE
        Pair :: (Type, Type) -> Type
        Pair := λ(KeyType, ValueType) { Record(key :: KeyType, value :: ValueType) }
        IntString := Pair(Int, String)
        p := IntString(42, "answer")
        p.key
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can access value field of multi-parameter type" do
      code = <<~STONE
        Pair :: (Type, Type) -> Type
        Pair := λ(KeyType, ValueType) { Record(key :: KeyType, value :: ValueType) }
        IntString := Pair(Int, String)
        p := IntString(42, "answer")
        p.value
      STONE
      expect(Stone.eval(code)).to eq("answer")
    end
  end

end
