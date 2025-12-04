require "stone"


RSpec.describe "Block Expressions" do

  describe "blocks as zero-parameter lambdas" do
    it "can be called directly" do
      code = <<~STONE
        result := { 42 }
        result()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "evaluates and returns the last statement" do
      code = <<~STONE
        block := {
          temp := sum(20, 20)
          sum(temp, 2)
        }
        block()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can reference constants" do
      code = <<~STONE
        FORTY_ONE := 41
        block := { sum(FORTY_ONE, ONE) }
        block()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

end
