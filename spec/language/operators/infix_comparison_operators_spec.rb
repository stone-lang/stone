require "stone"


RSpec.describe "Infix comparison operators" do

  describe "equality operator (==)" do
    it "returns true when integers are equal" do
      expect(Stone.eval("5 == 5")).to be(true)
      expect(Stone.eval("0 == 0")).to be(true)
      expect(Stone.eval("-10 == -10")).to be(true)
    end

    it "returns false when integers are not equal" do
      expect(Stone.eval("5 == 3")).to be(false)
      expect(Stone.eval("10 == -10")).to be(false)
    end

    it "requires whitespace around the operator" do
      # Without whitespace, these don't parse as comparisons
      # Instead they parse as multiple statements, with the last value returned
      expect(Stone.eval("5==5")).to eq(5)      # Parses as: 5; ==; 5
      expect(Stone.eval("5== 5")).to eq(5)     # Parses as: 5; ==; 5
      expect(Stone.eval("5 ==5")).to eq(5)     # Parses as: 5; ==; 5

      # Only with whitespace on both sides does it parse as a comparison
      expect(Stone.eval("5 == 5")).to be(true)
    end
  end

  describe "inequality operator (!=)" do
    it "returns true when integers are not equal" do
      expect(Stone.eval("5 != 3")).to be(true)
      expect(Stone.eval("10 != -10")).to be(true)
    end

    it "returns false when integers are equal" do
      expect(Stone.eval("5 != 5")).to be(false)
    end
  end

  describe "inequality operator with Unicode (≠)" do
    it "returns true when integers are not equal" do
      expect(Stone.eval("5 ≠ 3")).to be(true)
    end

    it "returns false when integers are equal" do
      expect(Stone.eval("5 ≠ 5")).to be(false)
    end
  end

  describe "less than operator (<)" do
    it "returns true when first is less than second" do
      expect(Stone.eval("3 < 5")).to be(true)
      expect(Stone.eval("-10 < 0")).to be(true)
    end

    it "returns false when first is greater than or equal to second" do
      expect(Stone.eval("5 < 3")).to be(false)
      expect(Stone.eval("5 < 5")).to be(false)
    end
  end

  describe "less than or equal operator (<=)" do
    it "returns true when first is less than or equal to second" do
      expect(Stone.eval("3 <= 5")).to be(true)
      expect(Stone.eval("5 <= 5")).to be(true)
    end

    it "returns false when first is greater than second" do
      expect(Stone.eval("5 <= 3")).to be(false)
    end
  end

  describe "less than or equal operator with Unicode (≤)" do
    it "returns true when first is less than or equal to second" do
      expect(Stone.eval("3 ≤ 5")).to be(true)
      expect(Stone.eval("5 ≤ 5")).to be(true)
    end

    it "returns false when first is greater than second" do
      expect(Stone.eval("5 ≤ 3")).to be(false)
    end
  end

  describe "greater than operator (>)" do
    it "returns true when first is greater than second" do
      expect(Stone.eval("5 > 3")).to be(true)
      expect(Stone.eval("0 > -10")).to be(true)
    end

    it "returns false when first is less than or equal to second" do
      expect(Stone.eval("3 > 5")).to be(false)
      expect(Stone.eval("5 > 5")).to be(false)
    end
  end

  describe "greater than or equal operator (>=)" do
    it "returns true when first is greater than or equal to second" do
      expect(Stone.eval("5 >= 3")).to be(true)
      expect(Stone.eval("5 >= 5")).to be(true)
    end

    it "returns false when first is less than second" do
      expect(Stone.eval("3 >= 5")).to be(false)
    end
  end

  describe "greater than or equal operator with Unicode (≥)" do
    it "returns true when first is greater than or equal to second" do
      expect(Stone.eval("5 ≥ 3")).to be(true)
      expect(Stone.eval("5 ≥ 5")).to be(true)
    end

    it "returns false when first is less than second" do
      expect(Stone.eval("3 ≥ 5")).to be(false)
    end
  end

  describe "with constants" do
    it "compares constants correctly" do
      expect(Stone.eval("ONE == ONE")).to be(true)
      expect(Stone.eval("ONE != ZERO")).to be(true)
      expect(Stone.eval("ZERO < ONE")).to be(true)
      expect(Stone.eval("ONE >= ZERO")).to be(true)
    end
  end

  describe "both syntaxes work equivalently" do
    it "infix and prefix produce same results" do
      expect(Stone.eval("5 == 3")).to eq(Stone.eval("==(5, 3)"))
      expect(Stone.eval("5 != 3")).to eq(Stone.eval("!=(5, 3)"))
      expect(Stone.eval("5 < 3")).to eq(Stone.eval("<(5, 3)"))
      expect(Stone.eval("5 <= 3")).to eq(Stone.eval("<=(5, 3)"))
      expect(Stone.eval("5 > 3")).to eq(Stone.eval(">(5, 3)"))
      expect(Stone.eval("5 >= 3")).to eq(Stone.eval(">=(5, 3)"))
    end
  end

end
