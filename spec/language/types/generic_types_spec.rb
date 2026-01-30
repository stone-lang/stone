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

  describe "recursive generic types" do
    it "allows recursive reference in generic type" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        List
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "can create a single-element linked list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(42, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can create a multi-element linked list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "can access elements via rest" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq(2)
    end

    it "works with string element type" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        StringList := List(String)
        list := StringList("hello", StringList("world", NULL))
        list.first
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end

    it "allows NULL as terminator for generic list type" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, NULL)
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "composed generic types" do
    it "can compose type constructors" do
      code = <<~STONE
        Maybe :: (Type) -> Type
        Maybe := λ(T) { Record(value :: T, present :: Bool) }

        List :: (Type) -> Type
        List := λ(T) { Record(first :: T, rest :: List(T)) }

        MaybeInt := Maybe(Int)
        ListMaybeInt := List(MaybeInt)
        ListMaybeInt
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

end
