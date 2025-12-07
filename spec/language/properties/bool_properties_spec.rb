require "stone"


RSpec.describe "Boolean Properties" do

  describe ".not" do
    it "returns FALSE for TRUE" do
      expect(Stone.eval("TRUE.not")).to be(false)
    end

    it "returns TRUE for FALSE" do
      expect(Stone.eval("FALSE.not")).to be(true)
    end

    it "works on references to boolean constants" do
      result = Stone.eval(<<~STONE)
        X := TRUE
        X.not
      STONE
      expect(result).to be(false)
    end

    it "works on references to FALSE constants" do
      result = Stone.eval(<<~STONE)
        Y := FALSE
        Y.not
      STONE
      expect(result).to be(true)
    end
  end

  describe "chaining .not" do
    it "double negation returns original value" do
      expect(Stone.eval("TRUE.not.not")).to be(true)
      expect(Stone.eval("FALSE.not.not")).to be(false)
    end

    it "triple negation returns negated value" do
      expect(Stone.eval("TRUE.not.not.not")).to be(false)
      expect(Stone.eval("FALSE.not.not.not")).to be(true)
    end
  end

end
