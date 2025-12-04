require "stone"


RSpec.describe "Integer comparison operators" do

  describe "equality operator (==)" do
    it "returns true when integers are equal" do
      expect(Stone.eval("==(5, 5)")).to be(true)
      expect(Stone.eval("==(0, 0)")).to be(true)
      expect(Stone.eval("==(-10, -10)")).to be(true)
    end

    it "returns false when integers are not equal" do
      expect(Stone.eval("==(5, 3)")).to be(false)
      expect(Stone.eval("==(10, -10)")).to be(false)
      expect(Stone.eval("==(0, 1)")).to be(false)
    end
  end

  describe "inequality operator (!=)" do
    it "returns false when integers are equal" do
      expect(Stone.eval("!=(5, 5)")).to be(false)
      expect(Stone.eval("!=(0, 0)")).to be(false)
      expect(Stone.eval("!=(-10, -10)")).to be(false)
    end

    it "returns true when integers are not equal" do
      expect(Stone.eval("!=(5, 3)")).to be(true)
      expect(Stone.eval("!=(10, -10)")).to be(true)
      expect(Stone.eval("!=(0, 1)")).to be(true)
    end
  end

  describe "inequality operator with Unicode (≠)" do
    it "returns false when integers are equal" do
      expect(Stone.eval("≠(5, 5)")).to be(false)
      expect(Stone.eval("≠(0, 0)")).to be(false)
    end

    it "returns true when integers are not equal" do
      expect(Stone.eval("≠(5, 3)")).to be(true)
      expect(Stone.eval("≠(10, -10)")).to be(true)
    end
  end

  describe "less than operator (<)" do
    it "returns true when first is less than second" do
      expect(Stone.eval("<(3, 5)")).to be(true)
      expect(Stone.eval("<(-10, 0)")).to be(true)
      expect(Stone.eval("<(-20, -10)")).to be(true)
    end

    it "returns false when first is greater than or equal to second" do
      expect(Stone.eval("<(5, 3)")).to be(false)
      expect(Stone.eval("<(5, 5)")).to be(false)
      expect(Stone.eval("<(0, -10)")).to be(false)
    end
  end

  describe "less than or equal operator (<=)" do
    it "returns true when first is less than or equal to second" do
      expect(Stone.eval("<=(3, 5)")).to be(true)
      expect(Stone.eval("<=(5, 5)")).to be(true)
      expect(Stone.eval("<=(-10, 0)")).to be(true)
    end

    it "returns false when first is greater than second" do
      expect(Stone.eval("<=(5, 3)")).to be(false)
      expect(Stone.eval("<=(0, -10)")).to be(false)
    end
  end

  describe "less than or equal operator with Unicode (≤)" do
    it "returns true when first is less than or equal to second" do
      expect(Stone.eval("≤(3, 5)")).to be(true)
      expect(Stone.eval("≤(5, 5)")).to be(true)
    end

    it "returns false when first is greater than second" do
      expect(Stone.eval("≤(5, 3)")).to be(false)
    end
  end

  describe "greater than operator (>)" do
    it "returns true when first is greater than second" do
      expect(Stone.eval(">(5, 3)")).to be(true)
      expect(Stone.eval(">(0, -10)")).to be(true)
      expect(Stone.eval(">(-10, -20)")).to be(true)
    end

    it "returns false when first is less than or equal to second" do
      expect(Stone.eval(">(3, 5)")).to be(false)
      expect(Stone.eval(">(5, 5)")).to be(false)
      expect(Stone.eval(">(-10, 0)")).to be(false)
    end
  end

  describe "greater than or equal operator (>=)" do
    it "returns true when first is greater than or equal to second" do
      expect(Stone.eval(">=(5, 3)")).to be(true)
      expect(Stone.eval(">=(5, 5)")).to be(true)
      expect(Stone.eval(">=(0, -10)")).to be(true)
    end

    it "returns false when first is less than second" do
      expect(Stone.eval(">=(3, 5)")).to be(false)
      expect(Stone.eval(">=(-10, 0)")).to be(false)
    end
  end

  describe "greater than or equal operator with Unicode (≥)" do
    it "returns true when first is greater than or equal to second" do
      expect(Stone.eval("≥(5, 3)")).to be(true)
      expect(Stone.eval("≥(5, 5)")).to be(true)
    end

    it "returns false when first is less than second" do
      expect(Stone.eval("≥(3, 5)")).to be(false)
    end
  end

  describe "with constants" do
    it "compares constants correctly" do
      expect(Stone.eval("==(ONE, ONE)")).to be(true)
      expect(Stone.eval("!=(ONE, ZERO)")).to be(true)
      expect(Stone.eval("<(ZERO, ONE)")).to be(true)
      expect(Stone.eval(">=(ONE, ZERO)")).to be(true)
    end
  end

  describe "with different literal formats" do
    it "compares binary literals" do
      expect(Stone.eval("==(0b101, 5)")).to be(true)
      expect(Stone.eval("<(0b11, 0b100)")).to be(true)
    end

    it "compares hexadecimal literals" do
      expect(Stone.eval("==(0x10, 16)")).to be(true)
      expect(Stone.eval(">(0x20, 0x10)")).to be(true)
    end

    it "compares octal literals" do
      expect(Stone.eval("==(0o10, 8)")).to be(true)
      expect(Stone.eval("<=(0o10, 10)")).to be(true)
    end
  end

end
