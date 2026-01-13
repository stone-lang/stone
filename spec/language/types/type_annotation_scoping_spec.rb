require "stone"
require "stone/scope"

RSpec.describe "Type Annotation Scoping" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "built-in types" do
    it "resolves Int in record field annotations" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        p.x
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "resolves Bool in record field annotations" do
      code = <<~STONE
        Flag := Record(value :: Bool)
        f := Flag(TRUE)
        f.value
      STONE
      expect(Stone.eval(code)).to be(true)
    end

    it "resolves String in record field annotations" do
      code = <<~STONE
        Named := Record(name :: String)
        n := Named("hello")
        n.name
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end
  end

  describe "type parameters in lambdas" do
    it "resolves T from lambda parameter in record field" do
      code = <<~STONE
        Box := λ(T) { Record(value :: T) }
        Box
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "resolves multiple type parameters" do
      code = <<~STONE
        Pair := λ(A, B) { Record(first :: A, second :: B) }
        Pair
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    # Generic type instantiation (Box(Int)) requires additional infrastructure
    # that is out of scope for type annotation scoping. See generic_types feature.
  end

  describe "error handling" do
    it "raises TypeError for undefined type reference in record field" do
      code = <<~STONE
        Bad := Record(value :: UndefinedType)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /Unknown type.*UndefinedType/)
    end

    it "provides helpful error message with the unknown type name" do
      code = <<~STONE
        Bad := Record(x :: Foo, y :: Bar)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /Foo/)
    end
  end

  describe "shadowing" do
    it "inner lambda parameter shadows outer lambda parameter" do
      code = <<~STONE
        Outer := λ(T) { λ(T) { Record(value :: T) } }
        Outer
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    # Type aliasing (T := Int) requires types as values, which is not yet implemented.
  end

  describe "scope chain" do
    it "can reference types from outer lambda scope" do
      code = <<~STONE
        Wrapper := λ(T) { λ() { Record(inner :: T) } }
        Wrapper
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    # Type aliasing (ElementType := Int) requires types as values, which is not yet implemented.
  end

end
