require "stone"


RSpec.describe "String Properties" do

  describe ".byte_count" do
    it "returns byte count for ASCII strings" do
      expect(Stone.eval('"hello".byte_count')).to eq(5)
      expect(Stone.eval('"a".byte_count')).to eq(1)
      expect(Stone.eval('"".byte_count')).to eq(0)
    end

    it "returns byte count for strings with spaces" do
      expect(Stone.eval('"hello world".byte_count')).to eq(11)
    end

    it "returns byte count for multi-byte UTF-8 characters" do
      expect(Stone.eval('"λ".byte_count')).to eq(2)       # Greek lambda is 2 bytes
      expect(Stone.eval('"hello λ".byte_count')).to eq(8) # 6 ASCII + 2 for λ
    end

    it "works on references to string constants" do
      result = Stone.eval(<<~STONE)
        S := "hello"
        S.byte_count
      STONE
      expect(result).to eq(5)
    end

    it "works on empty strings" do
      expect(Stone.eval('"".byte_count')).to eq(0)
    end
  end

end
