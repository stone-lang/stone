require "stone"


RSpec.describe "Boolean Operators" do

  describe "logical AND (and)" do
    describe "function form" do
      it "returns TRUE when both operands are TRUE" do
        expect(Stone.eval("and(TRUE, TRUE)")).to be(true)
      end

      it "returns FALSE when left is FALSE" do
        expect(Stone.eval("and(FALSE, TRUE)")).to be(false)
      end

      it "returns FALSE when right is FALSE" do
        expect(Stone.eval("and(TRUE, FALSE)")).to be(false)
      end

      it "returns FALSE when both are FALSE" do
        expect(Stone.eval("and(FALSE, FALSE)")).to be(false)
      end

      it "works with constants" do
        result = Stone.eval(<<~STONE)
          A := TRUE
          B := FALSE
          and(A, B)
        STONE
        expect(result).to be(false)
      end
    end

    describe "Unicode operator (∧)" do
      it "returns TRUE when both operands are TRUE" do
        expect(Stone.eval("∧(TRUE, TRUE)")).to be(true)
      end

      it "returns FALSE when either operand is FALSE" do
        expect(Stone.eval("∧(FALSE, TRUE)")).to be(false)
        expect(Stone.eval("∧(TRUE, FALSE)")).to be(false)
        expect(Stone.eval("∧(FALSE, FALSE)")).to be(false)
      end

      it "works with infix syntax" do
        expect(Stone.eval("TRUE ∧ TRUE")).to be(true)
        expect(Stone.eval("TRUE ∧ FALSE")).to be(false)
        expect(Stone.eval("FALSE ∧ TRUE")).to be(false)
        expect(Stone.eval("FALSE ∧ FALSE")).to be(false)
      end

      it "can chain the same operator" do
        expect(Stone.eval("TRUE ∧ TRUE ∧ TRUE")).to be(true)
        expect(Stone.eval("TRUE ∧ TRUE ∧ FALSE")).to be(false)
        expect(Stone.eval("TRUE ∧ FALSE ∧ TRUE")).to be(false)
      end
    end


    describe "properties" do
      it "is commutative" do
        expect(Stone.eval("TRUE ∧ FALSE")).to eq(Stone.eval("FALSE ∧ TRUE"))
      end

      it "is associative" do
        result1 = Stone.eval("(TRUE ∧ FALSE) ∧ TRUE")
        result2 = Stone.eval("TRUE ∧ (FALSE ∧ TRUE)")
        expect(result1).to eq(result2)
      end

      it "has TRUE as identity element" do
        expect(Stone.eval("TRUE ∧ TRUE")).to be(true)
        expect(Stone.eval("FALSE ∧ TRUE")).to be(false)
      end

      it "has FALSE as zero element" do
        expect(Stone.eval("TRUE ∧ FALSE")).to be(false)
        expect(Stone.eval("FALSE ∧ FALSE")).to be(false)
      end

      it "is idempotent" do
        expect(Stone.eval("TRUE ∧ TRUE")).to be(true)
        expect(Stone.eval("FALSE ∧ FALSE")).to be(false)
      end
    end
  end

  describe "logical OR (or)" do
    describe "function form" do
      it "returns TRUE when left is TRUE" do
        expect(Stone.eval("or(TRUE, FALSE)")).to be(true)
      end

      it "returns TRUE when right is TRUE" do
        expect(Stone.eval("or(FALSE, TRUE)")).to be(true)
      end

      it "returns TRUE when both are TRUE" do
        expect(Stone.eval("or(TRUE, TRUE)")).to be(true)
      end

      it "returns FALSE when both are FALSE" do
        expect(Stone.eval("or(FALSE, FALSE)")).to be(false)
      end

      it "works with constants" do
        result = Stone.eval(<<~STONE)
          A := TRUE
          B := FALSE
          or(A, B)
        STONE
        expect(result).to be(true)
      end
    end

    describe "Unicode operator (∨)" do
      it "returns TRUE when at least one operand is TRUE" do
        expect(Stone.eval("∨(TRUE, FALSE)")).to be(true)
        expect(Stone.eval("∨(FALSE, TRUE)")).to be(true)
        expect(Stone.eval("∨(TRUE, TRUE)")).to be(true)
      end

      it "returns FALSE when both operands are FALSE" do
        expect(Stone.eval("∨(FALSE, FALSE)")).to be(false)
      end

      it "works with infix syntax" do
        expect(Stone.eval("TRUE ∨ FALSE")).to be(true)
        expect(Stone.eval("FALSE ∨ TRUE")).to be(true)
        expect(Stone.eval("FALSE ∨ FALSE")).to be(false)
        expect(Stone.eval("TRUE ∨ TRUE")).to be(true)
      end

      it "can chain the same operator" do
        expect(Stone.eval("FALSE ∨ FALSE ∨ TRUE")).to be(true)
        expect(Stone.eval("FALSE ∨ FALSE ∨ FALSE")).to be(false)
        expect(Stone.eval("TRUE ∨ FALSE ∨ FALSE")).to be(true)
      end
    end


    describe "properties" do
      it "is commutative" do
        expect(Stone.eval("TRUE ∨ FALSE")).to eq(Stone.eval("FALSE ∨ TRUE"))
      end

      it "is associative" do
        result1 = Stone.eval("(TRUE ∨ FALSE) ∨ FALSE")
        result2 = Stone.eval("TRUE ∨ (FALSE ∨ FALSE)")
        expect(result1).to eq(result2)
      end

      it "has FALSE as identity element" do
        expect(Stone.eval("TRUE ∨ FALSE")).to be(true)
        expect(Stone.eval("FALSE ∨ FALSE")).to be(false)
      end

      it "has TRUE as zero element" do
        expect(Stone.eval("TRUE ∨ FALSE")).to be(true)
        expect(Stone.eval("TRUE ∨ TRUE")).to be(true)
      end

      it "is idempotent" do
        expect(Stone.eval("TRUE ∨ TRUE")).to be(true)
        expect(Stone.eval("FALSE ∨ FALSE")).to be(false)
      end
    end
  end

  describe "logical NOT (not)" do
    describe "function form" do
      it "negates TRUE to FALSE" do
        expect(Stone.eval("not(TRUE)")).to be(false)
      end

      it "negates FALSE to TRUE" do
        expect(Stone.eval("not(FALSE)")).to be(true)
      end

      it "double negation returns original" do
        expect(Stone.eval("not(not(TRUE))")).to be(true)
        expect(Stone.eval("not(not(FALSE))")).to be(false)
      end

      it "works with constants" do
        result = Stone.eval(<<~STONE)
          A := TRUE
          not(A)
        STONE
        expect(result).to be(false)
      end
    end

    describe "Unicode function (¬)" do
      it "negates TRUE to FALSE" do
        expect(Stone.eval("¬(TRUE)")).to be(false)
      end

      it "negates FALSE to TRUE" do
        expect(Stone.eval("¬(FALSE)")).to be(true)
      end

      it "double negation returns original" do
        expect(Stone.eval("¬(¬(TRUE))")).to be(true)
        expect(Stone.eval("¬(¬(FALSE))")).to be(false)
      end
    end


    describe "property form" do
      it "works via .not property (already tested in bool_properties_spec)" do
        expect(Stone.eval("TRUE.not")).to be(false)
        expect(Stone.eval("FALSE.not")).to be(true)
      end
    end

    describe "properties" do
      it "is involutive (double negation cancels)" do
        expect(Stone.eval("not(not(TRUE))")).to be(true)
        expect(Stone.eval("not(not(FALSE))")).to be(false)
      end
    end
  end

  describe "logical XOR (xor)" do
    describe "function form" do
      it "returns TRUE when operands differ" do
        expect(Stone.eval("xor(TRUE, FALSE)")).to be(true)
        expect(Stone.eval("xor(FALSE, TRUE)")).to be(true)
      end

      it "returns FALSE when operands are the same" do
        expect(Stone.eval("xor(TRUE, TRUE)")).to be(false)
        expect(Stone.eval("xor(FALSE, FALSE)")).to be(false)
      end

      it "works with constants" do
        result = Stone.eval(<<~STONE)
          A := TRUE
          B := FALSE
          xor(A, B)
        STONE
        expect(result).to be(true)
      end
    end

    describe "Unicode operator (⊻)" do
      it "returns TRUE when operands differ" do
        expect(Stone.eval("⊻(TRUE, FALSE)")).to be(true)
        expect(Stone.eval("⊻(FALSE, TRUE)")).to be(true)
      end

      it "returns FALSE when operands are the same" do
        expect(Stone.eval("⊻(TRUE, TRUE)")).to be(false)
        expect(Stone.eval("⊻(FALSE, FALSE)")).to be(false)
      end

      it "works with infix syntax" do
        expect(Stone.eval("TRUE ⊻ FALSE")).to be(true)
        expect(Stone.eval("FALSE ⊻ TRUE")).to be(true)
        expect(Stone.eval("TRUE ⊻ TRUE")).to be(false)
        expect(Stone.eval("FALSE ⊻ FALSE")).to be(false)
      end

      it "can chain the same operator" do
        expect(Stone.eval("TRUE ⊻ FALSE ⊻ TRUE")).to be(false)
        expect(Stone.eval("TRUE ⊻ TRUE ⊻ TRUE")).to be(true)
      end
    end

    describe "properties" do
      it "is commutative" do
        expect(Stone.eval("TRUE ⊻ FALSE")).to eq(Stone.eval("FALSE ⊻ TRUE"))
      end

      it "is associative" do
        result1 = Stone.eval("(TRUE ⊻ FALSE) ⊻ TRUE")
        result2 = Stone.eval("TRUE ⊻ (FALSE ⊻ TRUE)")
        expect(result1).to eq(result2)
      end

      it "has FALSE as identity element" do
        expect(Stone.eval("TRUE ⊻ FALSE")).to be(true)
        expect(Stone.eval("FALSE ⊻ FALSE")).to be(false)
      end

      it "is self-inverse" do
        expect(Stone.eval("TRUE ⊻ TRUE")).to be(false)
        expect(Stone.eval("FALSE ⊻ FALSE")).to be(false)
      end
    end

    describe "equivalence to != for Booleans" do
      it "gives same result as != operator" do
        expect(Stone.eval("TRUE ⊻ FALSE")).to eq(Stone.eval("TRUE != FALSE"))
        expect(Stone.eval("TRUE ⊻ TRUE")).to eq(Stone.eval("TRUE != TRUE"))
        expect(Stone.eval("FALSE ⊻ FALSE")).to eq(Stone.eval("FALSE != FALSE"))
      end
    end
  end

  describe "operator mixing" do
    it "requires parentheses when mixing AND and OR" do
      expect { Stone.eval("TRUE ∧ FALSE ∨ TRUE") }.to raise_error(/mixed.*operator/i)
    end

    it "requires parentheses when mixing AND and XOR" do
      expect { Stone.eval("TRUE ∧ FALSE ⊻ TRUE") }.to raise_error(/mixed.*operator/i)
    end

    it "requires parentheses when mixing OR and XOR" do
      expect { Stone.eval("TRUE ∨ FALSE ⊻ TRUE") }.to raise_error(/mixed.*operator/i)
    end

    it "allows repeated same operator" do
      expect(Stone.eval("TRUE ∧ TRUE ∧ FALSE")).to be(false)
      expect(Stone.eval("FALSE ∨ FALSE ∨ TRUE")).to be(true)
      expect(Stone.eval("TRUE ⊻ TRUE ⊻ TRUE")).to be(true)
    end

    it "allows mixing with parentheses" do
      expect(Stone.eval("(TRUE ∧ FALSE) ∨ TRUE")).to be(true)
      expect(Stone.eval("TRUE ∧ (FALSE ∨ TRUE)")).to be(true)
      expect(Stone.eval("(TRUE ⊻ FALSE) ∧ TRUE")).to be(true)
    end
  end

  describe "De Morgan's laws" do
    it "not(a ∧ b) == not(a) ∨ not(b)" do
      result1 = Stone.eval("not(TRUE ∧ FALSE)")
      result2 = Stone.eval("not(TRUE) ∨ not(FALSE)")
      expect(result1).to eq(result2)

      result3 = Stone.eval("not(FALSE ∧ FALSE)")
      result4 = Stone.eval("not(FALSE) ∨ not(FALSE)")
      expect(result3).to eq(result4)
    end

    it "not(a ∨ b) == not(a) ∧ not(b)" do
      result1 = Stone.eval("not(TRUE ∨ FALSE)")
      result2 = Stone.eval("not(TRUE) ∧ not(FALSE)")
      expect(result1).to eq(result2)

      result3 = Stone.eval("not(TRUE ∨ TRUE)")
      result4 = Stone.eval("not(TRUE) ∧ not(TRUE)")
      expect(result3).to eq(result4)
    end
  end

  describe "combining with comparison operators" do
    it "works with comparisons in parentheses" do
      expect(Stone.eval("(5 > 3) ∧ (10 < 20)")).to be(true)
      expect(Stone.eval("(5 > 3) ∧ (10 > 20)")).to be(false)
      expect(Stone.eval("(5 < 3) ∨ (10 < 20)")).to be(true)
    end

    it "works with equality operators" do
      expect(Stone.eval("(5 == 5) ∧ (10 == 10)")).to be(true)
      expect(Stone.eval("(5 == 3) ∨ (10 == 10)")).to be(true)
    end
  end

  describe "operator equivalence" do

    it "function and operator forms are equivalent" do
      expect(Stone.eval("and(TRUE, FALSE)")).to eq(Stone.eval("TRUE ∧ FALSE"))
      expect(Stone.eval("or(TRUE, FALSE)")).to eq(Stone.eval("TRUE ∨ FALSE"))
      expect(Stone.eval("xor(TRUE, FALSE)")).to eq(Stone.eval("TRUE ⊻ FALSE"))
      expect(Stone.eval("not(TRUE)")).to eq(Stone.eval("¬(TRUE)"))
    end
  end

end
