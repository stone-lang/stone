require "stone"
require "stone/scope"


RSpec.describe "Lambda Parameter Types" do
  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "computed properties on record types" do
    it "passes a record to a lambda and accesses its fields", pending: "requires lambda param type generalization" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point@add :: (Point) -> Int
        Point@add := λ(self) { sum(self.x, self.y) }
        pt := Point(3, 4)
        pt.add
      STONE
      expect(Stone.eval(code)).to eq(7)
    end

    it "works with single-field records", pending: "requires lambda param type generalization" do
      code = <<~STONE
        Box := Record(value :: Int)
        Box@unwrap :: (Box) -> Int
        Box@unwrap := λ(self) { self.value }
        b := Box(42)
        b.unwrap
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "computed properties on sum types" do
    it "passes a sum type value to a lambda", pending: "requires lambda param type generalization" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? :: (List) -> Bool
        List@empty? := λ(list) { list == NULL }
        list := IntList(1, NULL)
        list.empty?
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "handles NULL variant of a sum type", pending: "requires union constructor dispatch - see docs/prompts/union-constructor-dispatch.md" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? :: (List) -> Bool
        List@empty? := λ(list) { list == NULL }
        empty := NULL
        empty.empty?
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "string parameter handling" do
    it "passes a string to a lambda and returns it", pending: "requires lambda param type generalization" do
      code = <<~STONE
        String@shout :: (String) -> String
        String@shout := λ(self) { self }
        s := "hello"
        s.shout
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end
  end

  describe "standalone lambda with type declaration" do
    it "accepts a record parameter via explicit type declaration", pending: "requires lambda param type generalization" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        add_fields :: (Point) -> Int
        add_fields := λ(pt) { sum(pt.x, pt.y) }
        add_fields(Point(10, 20))
      STONE
      expect(Stone.eval(code)).to eq(30)
    end
  end

  describe "primitive parameters (regression tests)" do
    context "without type declaration" do
      it "passes an integer to a computed property lambda" do
        code = <<~STONE
          Int@double := λ(self) { sum(self, self) }
          x := 21
          x.double
        STONE
        expect(Stone.eval(code)).to eq(42)
      end

      it "passes a boolean to a computed property lambda" do
        # NOTE: Re-uses Bool@not property name because test isolation issues
        # cause newly-defined properties to fail in certain test orderings.
        # This test verifies boolean computed properties work with references.
        code = <<~STONE
          Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
          b := TRUE
          b.not
        STONE
        expect(Stone.eval(code)).to be false
      end
    end

    context "with type declaration" do
      it "passes an integer to a computed property lambda with explicit type" do
        code = <<~STONE
          Int@triple :: (Int) -> Int
          Int@triple := λ(self) { sum(self, sum(self, self)) }
          x := 10
          x.triple
        STONE
        expect(Stone.eval(code)).to eq(30)
      end
    end
  end

end
