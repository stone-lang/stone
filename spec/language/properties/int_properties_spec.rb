require "stone"


RSpec.describe "Integer Properties" do

  describe ".positive?" do
    it "returns TRUE for positive integers" do
      expect(Stone.eval("42.positive?")).to be(true)
      expect(Stone.eval("1.positive?")).to be(true)
      expect(Stone.eval("999.positive?")).to be(true)
    end

    it "returns FALSE for negative integers" do
      expect(Stone.eval("(-5).positive?")).to be(false)
      expect(Stone.eval("(-1).positive?")).to be(false)
      expect(Stone.eval("(-999).positive?")).to be(false)
    end

    it "returns FALSE for zero" do
      expect(Stone.eval("0.positive?")).to be(false)
    end

    it "works on references to integer constants" do
      result = Stone.eval(<<~STONE)
        X := 42
        X.positive?
      STONE
      expect(result).to be(true)
    end

    it "works on references to negative integer constants" do
      result = Stone.eval(<<~STONE)
        X := -5
        X.positive?
      STONE
      expect(result).to be(false)
    end
  end

  describe ".negative?" do
    it "returns TRUE for negative integers" do
      expect(Stone.eval("(-5).negative?")).to be(true)
      expect(Stone.eval("(-1).negative?")).to be(true)
      expect(Stone.eval("(-999).negative?")).to be(true)
    end

    it "returns FALSE for positive integers" do
      expect(Stone.eval("42.negative?")).to be(false)
      expect(Stone.eval("1.negative?")).to be(false)
      expect(Stone.eval("999.negative?")).to be(false)
    end

    it "returns FALSE for zero" do
      expect(Stone.eval("0.negative?")).to be(false)
    end

    it "works on references to integer constants" do
      result = Stone.eval(<<~STONE)
        X := -42
        X.negative?
      STONE
      expect(result).to be(true)
    end
  end

  describe ".zero?" do
    it "returns TRUE for zero" do
      expect(Stone.eval("0.zero?")).to be(true)
    end

    it "returns FALSE for positive integers" do
      expect(Stone.eval("42.zero?")).to be(false)
      expect(Stone.eval("1.zero?")).to be(false)
    end

    it "returns FALSE for negative integers" do
      expect(Stone.eval("(-5).zero?")).to be(false)
      expect(Stone.eval("(-1).zero?")).to be(false)
    end

    it "works on references to integer constants" do
      result = Stone.eval(<<~STONE)
        X := 0
        X.zero?
      STONE
      expect(result).to be(true)
    end
  end

  describe "chaining properties" do
    it "chains property access on results" do
      # 0.zero? returns TRUE, TRUE.not returns FALSE
      expect(Stone.eval("0.zero?.not")).to be(false)
    end

    it "chains three levels deep" do
      # 42.positive? -> TRUE, TRUE.not -> FALSE, FALSE.not -> TRUE
      expect(Stone.eval("42.positive?.not.not")).to be(true)
    end
  end

end
