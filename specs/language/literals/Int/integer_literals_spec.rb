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
    expect(Stone.eval("1000000")).to eq(1_000_000)
    expect(Stone.eval("2147483647")).to eq(2_147_483_647)  # Max 32-bit signed
  end

  it "supports large negative integers" do
    expect(Stone.eval("-1000000")).to eq(-1_000_000)
    expect(Stone.eval("-2147483648")).to eq(-2_147_483_648)  # Min 32-bit signed
  end

  describe "binary integer literals" do
    it "supports binary literals" do
      expect(Stone.eval("0b0")).to eq(0)
      expect(Stone.eval("0b1")).to eq(1)
      expect(Stone.eval("0b10")).to eq(2)
      expect(Stone.eval("0b1010")).to eq(10)
      expect(Stone.eval("0b11111111")).to eq(255)
    end

    it "supports signed binary literals" do
      expect(Stone.eval("+0b101")).to eq(5)
      expect(Stone.eval("-0b101")).to eq(-5)
      expect(Stone.eval("-0b11111111")).to eq(-255)
    end
  end

  describe "octal integer literals" do
    it "supports octal literals" do
      expect(Stone.eval("0o0")).to eq(0)
      expect(Stone.eval("0o7")).to eq(7)
      expect(Stone.eval("0o10")).to eq(8)
      expect(Stone.eval("0o77")).to eq(63)
      expect(Stone.eval("0o777")).to eq(511)
    end

    it "supports signed octal literals" do
      expect(Stone.eval("+0o10")).to eq(8)
      expect(Stone.eval("-0o10")).to eq(-8)
      expect(Stone.eval("-0o777")).to eq(-511)
    end
  end

  describe "hexadecimal integer literals" do
    it "supports hex literals" do
      expect(Stone.eval("0x0")).to eq(0)
      expect(Stone.eval("0x9")).to eq(9)
      expect(Stone.eval("0xa")).to eq(10)
      expect(Stone.eval("0xf")).to eq(15)
      expect(Stone.eval("0x10")).to eq(16)
      expect(Stone.eval("0xff")).to eq(255)
      expect(Stone.eval("0xdeadbeef")).to eq(3_735_928_559)
    end

    it "supports hex literals with mixed case digits" do
      expect(Stone.eval("0xAa")).to eq(170)
      expect(Stone.eval("0xDeAdBeEf")).to eq(3_735_928_559)
    end

    it "supports signed hex literals" do
      expect(Stone.eval("+0x10")).to eq(16)
      expect(Stone.eval("-0x10")).to eq(-16)
      expect(Stone.eval("-0xff")).to eq(-255)
    end
  end

end
# rubocop:enable RSpec/DescribeClass
