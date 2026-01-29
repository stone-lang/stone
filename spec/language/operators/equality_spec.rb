require "stone"


RSpec.describe "Universal equality" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "Bool equality" do
    it "TRUE equals TRUE" do
      expect(Stone.eval("TRUE == TRUE")).to be(true)
    end

    it "FALSE equals FALSE" do
      expect(Stone.eval("FALSE == FALSE")).to be(true)
    end

    it "TRUE does not equal FALSE" do
      expect(Stone.eval("TRUE == FALSE")).to be(false)
    end

    it "FALSE does not equal TRUE" do
      expect(Stone.eval("FALSE == TRUE")).to be(false)
    end

    it "!= returns true for different booleans" do
      expect(Stone.eval("TRUE != FALSE")).to be(true)
    end

    it "!= returns false for same booleans" do
      expect(Stone.eval("TRUE != TRUE")).to be(false)
    end

    it "works with Unicode inequality" do
      expect(Stone.eval("TRUE ≠ FALSE")).to be(true)
    end
  end

  describe "String equality" do
    it "equal strings are equal" do
      expect(Stone.eval('"hello" == "hello"')).to be(true)
    end

    it "different strings are not equal" do
      expect(Stone.eval('"hello" == "world"')).to be(false)
    end

    it "empty strings are equal" do
      expect(Stone.eval('"" == ""')).to be(true)
    end

    it "empty and non-empty strings are not equal" do
      expect(Stone.eval('"" == "x"')).to be(false)
    end

    it "!= returns true for different strings" do
      expect(Stone.eval('"hello" != "world"')).to be(true)
    end

    it "!= returns false for equal strings" do
      expect(Stone.eval('"hello" != "hello"')).to be(false)
    end
  end

  describe "cross-type comparison" do
    it "Int vs String returns false" do
      expect(Stone.eval('42 == "42"')).to be(false)
    end

    it "Int vs Bool returns false" do
      expect(Stone.eval("1 == TRUE")).to be(false)
    end

    it "Bool vs String returns false" do
      expect(Stone.eval('TRUE == "true"')).to be(false)
    end

    it "0 vs FALSE returns false (different types)" do
      expect(Stone.eval("0 == FALSE")).to be(false)
    end

    it "cross-type != returns true" do
      expect(Stone.eval('42 != "42"')).to be(true)
    end

    it "String vs NULL returns false" do
      expect(Stone.eval('"hello" == NULL')).to be(false)
    end

    it "Bool vs NULL returns false" do
      expect(Stone.eval("TRUE == NULL")).to be(false)
    end
  end

  describe "nested record equality" do
    it "equal nested records are equal" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Rect := Record(origin :: Point, size :: Point)
        r1 := Rect(Point(0, 0), Point(10, 20))
        r2 := Rect(Point(0, 0), Point(10, 20))
        r1 == r2
      STONE
      expect(Stone.eval(code)).to be(true)
    end

    it "different nested records are not equal" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Rect := Record(origin :: Point, size :: Point)
        r1 := Rect(Point(0, 0), Point(10, 20))
        r2 := Rect(Point(1, 1), Point(10, 20))
        r1 == r2
      STONE
      expect(Stone.eval(code)).to be(false)
    end

    it "!= works for nested records" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Rect := Record(origin :: Point, size :: Point)
        r1 := Rect(Point(0, 0), Point(10, 20))
        r2 := Rect(Point(1, 1), Point(10, 20))
        r1 != r2
      STONE
      expect(Stone.eval(code)).to be(true)
    end
  end

  describe "union field equality" do
    describe "nullable Int field (Int | Null)" do
      it "equal when both have same Int value" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(42) == Foo(42)
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "not equal when Int values differ" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(42) == Foo(99)
        STONE
        expect(Stone.eval(code)).to be(false)
      end

      it "equal when both are null" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(NULL) == Foo(NULL)
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "not equal when one is null and other is not" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(42) == Foo(NULL)
        STONE
        expect(Stone.eval(code)).to be(false)
      end
    end

    describe "nullable String field (String | Null)" do
      it "equal when both have same String value" do
        code = <<~STONE
          Bar := Record(s :: String | Null)
          Bar("hello") == Bar("hello")
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "not equal when String values differ" do
        code = <<~STONE
          Bar := Record(s :: String | Null)
          Bar("hello") == Bar("world")
        STONE
        expect(Stone.eval(code)).to be(false)
      end
    end

    describe "nullable Record field (Record | Null)" do
      it "equal when both have same record value" do
        code = <<~STONE
          Point := Record(x :: Int, y :: Int)
          Box := Record(origin :: Point | Null)
          Box(Point(1, 2)) == Box(Point(1, 2))
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "not equal when record values differ" do
        code = <<~STONE
          Point := Record(x :: Int, y :: Int)
          Box := Record(origin :: Point | Null)
          Box(Point(1, 2)) == Box(Point(3, 4))
        STONE
        expect(Stone.eval(code)).to be(false)
      end

      it "not equal when one is null" do
        code = <<~STONE
          Point := Record(x :: Int, y :: Int)
          Box := Record(origin :: Point | Null)
          Box(Point(1, 2)) == Box(NULL)
        STONE
        expect(Stone.eval(code)).to be(false)
      end
    end

    describe "mixed regular and union fields" do
      it "compares both regular and union fields" do
        code = <<~STONE
          Foo := Record(name :: String, value :: Int | Null)
          Foo("x", 42) == Foo("x", 42)
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "not equal when regular field differs" do
        code = <<~STONE
          Foo := Record(name :: String, value :: Int | Null)
          Foo("x", 42) == Foo("y", 42)
        STONE
        expect(Stone.eval(code)).to be(false)
      end

      it "not equal when union field differs" do
        code = <<~STONE
          Foo := Record(name :: String, value :: Int | Null)
          Foo("x", 42) == Foo("x", NULL)
        STONE
        expect(Stone.eval(code)).to be(false)
      end
    end

    describe "!= with union fields" do
      it "returns true when union values differ" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(42) != Foo(NULL)
        STONE
        expect(Stone.eval(code)).to be(true)
      end

      it "returns false when union values are equal" do
        code = <<~STONE
          Foo := Record(x :: Int | Null)
          Foo(42) != Foo(42)
        STONE
        expect(Stone.eval(code)).to be(false)
      end
    end
  end

  describe "!= as logical negation of ==" do
    it "is false when == is true for Int" do
      expect(Stone.eval("5 != 5")).to be(false)
    end

    it "is true when == is false for Int" do
      expect(Stone.eval("5 != 3")).to be(true)
    end

    it "is false when == is true for NULL" do
      expect(Stone.eval("NULL != NULL")).to be(false)
    end

    it "is true when == is false for NULL vs Int" do
      expect(Stone.eval("NULL != 42")).to be(true)
    end
  end

end
