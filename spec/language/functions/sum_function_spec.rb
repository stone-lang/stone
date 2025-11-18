require "stone"


RSpec.describe "sum built-in function" do

  describe "basic addition" do
    it "adds two positive integers" do
      expect(Stone.eval("sum(5, 3)")).to eq(8)
      expect(Stone.eval("sum(100, 200)")).to eq(300)
      expect(Stone.eval("sum(1, 1)")).to eq(2)
    end

    it "adds negative and positive integers" do
      expect(Stone.eval("sum(-5, 3)")).to eq(-2)
      expect(Stone.eval("sum(10, -20)")).to eq(-10)
    end

    it "adds two negative integers" do
      expect(Stone.eval("sum(-10, -20)")).to eq(-30)
      expect(Stone.eval("sum(-5, -5)")).to eq(-10)
    end

    it "adds with zero" do
      expect(Stone.eval("sum(0, 0)")).to eq(0)
      expect(Stone.eval("sum(42, 0)")).to eq(42)
      expect(Stone.eval("sum(0, 42)")).to eq(42)
    end
  end

  describe "with predefined constants" do
    it "adds constants" do
      expect(Stone.eval("sum(ONE, ONE)")).to eq(2)
      expect(Stone.eval("sum(ZERO, ONE)")).to eq(1)
      expect(Stone.eval("sum(ONE, ZERO)")).to eq(1)
    end

    it "mixes constants and literals" do
      expect(Stone.eval("sum(ONE, 5)")).to eq(6)
      expect(Stone.eval("sum(10, ONE)")).to eq(11)
    end
  end

  describe "with different literal formats" do
    it "supports binary literals" do
      expect(Stone.eval("sum(0b101, 0b11)")).to eq(8)  # 5 + 3
    end

    it "supports octal literals" do
      expect(Stone.eval("sum(0o12, 0o10)")).to eq(18)  # 10 + 8
    end

    it "supports hexadecimal literals" do
      expect(Stone.eval("sum(0x10, 0x20)")).to eq(48)  # 16 + 32
    end

    it "mixes different literal formats" do
      expect(Stone.eval("sum(10, 0x0A)")).to eq(20)  # 10 + 10
      expect(Stone.eval("sum(0b100, 8)")).to eq(12)  # 4 + 8
    end
  end

  describe "with large numbers" do
    it "handles large positive numbers" do
      expect(Stone.eval("sum(1000000, 2000000)")).to eq(3_000_000)
    end

    it "handles large negative numbers" do
      expect(Stone.eval("sum(-1000000, -2000000)")).to eq(-3_000_000)
    end
  end

  describe "error handling" do
    it "requires exactly 2 arguments" do
      expect { Stone.eval("sum(1)") }.to raise_error(/requires exactly 2 arguments/)
      expect { Stone.eval("sum(1, 2, 3)") }.to raise_error(/requires exactly 2 arguments/)
    end
  end

end
