require "stone"

# Language Specification: Integer Literals
#
# This spec serves as both executable documentation and verification
# that the Stone language correctly implements integer literal semantics.

RSpec.describe "Integer Literals" do

  describe "basic integer literals" do
    it "evaluates to their numeric value" do
      expect(Stone.eval("0")).to eq(0)
      expect(Stone.eval("1")).to eq(1)
      expect(Stone.eval("42")).to eq(42)
      expect(Stone.eval("999")).to eq(999)
    end
  end

  describe "signed integer literals" do
    it "supports positive sign prefix" do
      expect(Stone.eval("+5")).to eq(5)
      expect(Stone.eval("+100")).to eq(100)
    end

    it "supports negative sign prefix" do
      expect(Stone.eval("-1")).to eq(-1)
      expect(Stone.eval("-42")).to eq(-42)
      expect(Stone.eval("-999")).to eq(-999)
    end
  end


  it "supports large integers" do
    expect(Stone.eval("1000000")).to eq(1000000)
    expect(Stone.eval("2147483647")).to eq(2147483647)  # Max 32-bit signed
  end

  it "supports large negative integers" do
    expect(Stone.eval("-1000000")).to eq(-1000000)
    expect(Stone.eval("-2147483648")).to eq(-2147483648)  # Min 32-bit signed
  end

end
