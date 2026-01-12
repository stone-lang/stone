require "stone"


RSpec.describe "Scope" do

  describe "block scoping" do
    it "shadows definitions in blocks" do
      code = <<~STONE
        x := 1
        { x := 2 }
        x
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "preserves outer scope after block" do
      code = <<~STONE
        x := 1
        y := { x := 10; x }
        x
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "allows inner block to capture shadowed value" do
      code = <<~STONE
        x := 1
        y := { x := 10; x }
        y()
      STONE
      expect(Stone.eval(code)).to eq(10)
    end

    it "accesses outer scope when no inner definition exists" do
      code = <<~STONE
        x := 42
        result := { x }
        result()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "shadows across multiple nested blocks" do
      code = <<~STONE
        x := 1
        {
          x := 2
          { x := 3 }
          x
        }
        x
      STONE
      expect(Stone.eval(code)).to eq(1)
    end
  end

  describe "lambda scoping" do
    it "creates child scope for lambda parameters" do
      code = <<~STONE
        x := 1
        f := λ(x) { sum(x, 21) }
        f(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "preserves outer scope after lambda call" do
      code = <<~STONE
        x := 10
        f := λ(y) { sum(y, 5) }
        f(5)
        x
      STONE
      expect(Stone.eval(code)).to eq(10)
    end

    it "accesses outer scope variables from lambda" do
      code = <<~STONE
        addend := 21
        f := λ(x) { sum(x, addend) }
        f(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "shadows outer variable with parameter" do
      code = <<~STONE
        n := 100
        f := λ(n) { n }
        f(42)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

end
