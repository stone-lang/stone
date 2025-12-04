require "stone"


RSpec.describe "if Function" do

  describe "with Boolean literals" do
    it "executes the then block when condition is TRUE" do
      code = <<~STONE
        if(TRUE, { 42 }, { 0 })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "executes the else block when condition is FALSE" do
      code = <<~STONE
        if(FALSE, { 0 }, { 42 })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "with comparison operations" do
    it "works with equality comparison" do
      code = <<~STONE
        if(==(5, 5), { 42 }, { 0 })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "works with less than comparison" do
      code = <<~STONE
        if(<(3, 5), { 42 }, { 0 })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "works with greater than comparison" do
      code = <<~STONE
        if(>(10, 5), { 42 }, { 0 })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "with complex blocks" do
    it "evaluates multiple statements in the selected block" do
      code = <<~STONE
        if(TRUE, {
          temp := sum(20, 20)
          sum(temp, 2)
        }, {
          0
        })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can reference constants in blocks" do
      code = <<~STONE
        FORTY_ONE := 41
        if(TRUE, { sum(FORTY_ONE, ONE) }, { ZERO })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "nested conditionals" do
    it "can nest if expressions" do
      code = <<~STONE
        if(TRUE, {
          if(FALSE, { 0 }, { 42 })
        }, {
          0
        })
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "using blocks assigned to constants" do
    it "can pass blocks stored in constants" do
      code = <<~STONE
        then_branch := { 42 }
        else_branch := { 0 }
        if(TRUE, then_branch, else_branch)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

end
