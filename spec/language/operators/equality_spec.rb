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
