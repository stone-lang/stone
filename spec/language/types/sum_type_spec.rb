require "stone"
require "stone/scope"


RSpec.describe "Sum Types" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "basic expression-level union" do
    it "creates a union type from two types" do
      code = <<~STONE
        MyType := Int | String
        MyType
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "creates a union from Null and a Record" do
      code = <<~STONE
        IntOption := Null | Record(value :: Int)
        IntOption
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "creates a multi-alternative union" do
      code = <<~STONE
        Triple := Int | String | Bool
        Triple
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "non-generic sum types" do
    it "constructs a Record variant and accesses its field" do
      code = <<~STONE
        IntOption := Null | Record(value :: Int)
        some := IntOption(42)
        some.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows NULL as the Null variant" do
      code = <<~STONE
        IntOption := Null | Record(value :: Int)
        none := NULL
        none == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "generic sum types" do
    it "defines a generic sum type via type-level lambda" do
      code = <<~STONE
        Option :: (Type) -> Type
        Option := λ(T) { Null | Record(value :: T) }
        Option
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "instantiates a generic sum type" do
      code = <<~STONE
        Option :: (Type) -> Type
        Option := λ(T) { Null | Record(value :: T) }
        IntOption := Option(Int)
        IntOption
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "constructs a Record variant via instantiated generic sum type" do
      code = <<~STONE
        Option :: (Type) -> Type
        Option := λ(T) { Null | Record(value :: T) }
        IntOption := Option(Int)
        some := IntOption(42)
        some.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows NULL as the empty variant of a generic sum type" do
      code = <<~STONE
        Option :: (Type) -> Type
        Option := λ(T) { Null | Record(value :: T) }
        IntOption := Option(Int)
        none := NULL
        none == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "recursive sum types" do
    it "defines a recursive List type" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        IntList
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "constructs a single-element list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "constructs a multi-element list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "traverses the list via .rest" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    it "terminates the list with NULL" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(1, NULL)
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "Type.of() on sum type values" do
    it "returns Null for NULL" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        Type.of(NULL).as_String
      STONE
      expect(Stone.eval(code)).to eq("Null")
    end

    it "returns a non-Null type for the data variant" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(42, NULL)
        Type.of(list).as_String
      STONE
      expect(Stone.eval(code)).not_to eq("Null")
    end
  end

  describe "computed properties on sum types" do
    # Computed property lookup falls back to generic base name (List@empty? for List(Int)).
    # However, these tests are pending because Stone's lambda infrastructure assumes all
    # parameters are i64. Passing record structs or union pointers to computed property
    # lambdas requires lambda parameter type generalization.
    it "supports computed properties defined on the generic base name" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? := λ(list) { list == NULL }
        list := IntList(1, NULL)
        list.empty?
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns TRUE for an empty list", pending: "requires union constructor dispatch - see docs/prompts/union-constructor-dispatch.md" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? := λ(list) { list == NULL }
        empty := NULL
        empty.empty?
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "equality" do
    it "NULL equals NULL" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        NULL == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "a non-empty list does not equal NULL" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        list := IntList(42, NULL)
        list == NULL
      STONE
      expect(Stone.eval(code)).to be false
    end
  end

end
