require "stone/ast/string_literal"


RSpec.describe Stone::AST::StringLiteral do
  describe ".parse" do
    it "parses a simple string" do
      result = described_class.parse('"hello"', nil)
      expect(result.value).to eq("hello")
    end

    it "parses an empty string" do
      result = described_class.parse('""', nil)
      expect(result.value).to eq("")
    end

    it "removes quotes but does not process escape sequences" do
      result = described_class.parse('"hello\nworld"', nil)
      expect(result.value).to eq('hello\nworld')
    end

    it "handles strings with hash characters" do
      result = described_class.parse('"hello # comment"', nil)
      expect(result.value).to eq("hello # comment")
    end
  end

  describe "#initialize" do
    it "sets the name to :string_literal" do
      literal = described_class.new("test")
      expect(literal.name).to eq(:string_literal)
    end

    it "stores the value" do
      literal = described_class.new("test")
      expect(literal.value).to eq("test")
    end
  end

  describe "#bytesize" do
    it "returns byte count for ASCII strings" do
      literal = described_class.new("hello")
      expect(literal.bytesize).to eq(5)
    end

    it "returns byte count for Unicode strings" do
      literal = described_class.new("λ")
      expect(literal.bytesize).to eq(2)
    end
  end

  describe "#length" do
    it "returns character count for ASCII strings" do
      literal = described_class.new("hello")
      expect(literal.length).to eq(5)
    end

    it "returns character count for Unicode strings" do
      literal = described_class.new("λ")
      expect(literal.length).to eq(1)
    end

    it "differs from bytesize for multi-byte characters" do
      literal = described_class.new("hello λ world")
      expect(literal.length).to eq(13)
      expect(literal.bytesize).to eq(14)
    end
  end
end
