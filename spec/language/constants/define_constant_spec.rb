require "stone"


RSpec.describe "Define Constant" do

  describe "defining a constant with a literal" do
    it "allows that constant to be referenced" do
      expect(Stone.eval("TWO := 2\nTWO")).to eq(2)
    end
  end

  describe "defining a constant with a function call" do
    it "evaluates the function and stores the result" do
      expect(Stone.eval("THREE := sum(1, 2)\nTHREE")).to eq(3)
    end
  end

  describe "defining a constant with a reference to another constant" do
    it "copies the value of the referenced constant" do
      expect(Stone.eval("ONE := 1\nCOPY := ONE\nCOPY")).to eq(1)
    end
  end

  describe "defining a constant with a complex expression" do
    it "evaluates the expression using other constants" do
      expect(Stone.eval("ONE := 1\nTWO := 2\nTHREE := sum(ONE, TWO)\nTHREE")).to eq(3)
    end
  end

end
