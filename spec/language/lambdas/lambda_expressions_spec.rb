require "stone"


RSpec.describe "Lambda Expressions" do

  describe "defining a lambda with no parameters" do
    it "can be stored in a constant and called" do
      code = <<~STONE
        get_answer := λ() { 42 }
        get_answer()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "defining a lambda with one parameter" do
    it "can use the parameter in its body" do
      code = <<~STONE
        double := λ(x) { sum(x, x) }
        double(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "defining a lambda with two parameters" do
    it "can use both parameters in its body" do
      code = <<~STONE
        add := λ(x, y) { sum(x, y) }
        add(20, 22)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "lambda with multiple statements" do
    it "returns the value of the last statement" do
      code = <<~STONE
        compute := λ(x) {
          temp := sum(x, x)
          sum(temp, ONE)
        }
        compute(20)
      STONE
      expect(Stone.eval(code)).to eq(41)
    end

    it "allows comments in the body" do
      code = <<~STONE
        compute := λ(x) {
          # Double the input
          temp := sum(x, x)
          # Add one
          sum(temp, ONE)
        }
        compute(20)
      STONE
      expect(Stone.eval(code)).to eq(41)
    end
  end

  describe "using constants inside lambda body" do
    it "can reference predefined constants" do
      code = <<~STONE
        add_one := λ(x) { sum(x, ONE) }
        add_one(41)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can reference user-defined constants" do
      code = <<~STONE
        TEN := 10
        add_ten := λ(x) { sum(x, TEN) }
        add_ten(32)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "multiple lambdas" do
    it "can define and use multiple different lambdas" do
      code = <<~STONE
        double := λ(x) { sum(x, x) }
        triple := λ(x) { sum(sum(x, x), x) }
        result := sum(double(10), triple(7))
        result
      STONE
      expect(Stone.eval(code)).to eq(41)
    end
  end

end
