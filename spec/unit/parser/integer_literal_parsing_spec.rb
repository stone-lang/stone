require "stone/grammar"

RSpec.describe "Integer Literal Parsing" do

  describe "decimal integers" do
    it "parses positive integers" do
      expect("42").to parse_as(:literal_i64)
    end

    it "parses negative integers" do
      expect("-17").to parse_as(:literal_i64)
    end

    it "parses zero" do
      expect("0").to parse_as(:literal_i64)
    end
  end

  describe "binary integers" do
    it "parses binary integers" do
      expect("0b1010").to parse_as(:literal_i64)
    end

    it "parses negative binary integers" do
      expect("-0b101").to parse_as(:literal_i64)
    end

    it "parses positive signed binary integers" do
      expect("+0b101").to parse_as(:literal_i64)
    end
  end

  describe "octal integers" do
    it "parses octal integers" do
      expect("0o777").to parse_as(:literal_i64)
    end

    it "parses negative octal integers" do
      expect("-0o77").to parse_as(:literal_i64)
    end

    it "parses positive signed octal integers" do
      expect("+0o123").to parse_as(:literal_i64)
    end
  end

  describe "hexadecimal integers" do
    it "parses hex integers" do
      expect("0xff").to parse_as(:literal_i64)
    end

    it "parses hex integers with mixed case digits" do
      expect("0xDeAdBeEf").to parse_as(:literal_i64)
    end

    it "parses negative hex integers" do
      expect("-0xff").to parse_as(:literal_i64)
    end

    it "parses positive signed hex integers" do
      expect("+0xABC").to parse_as(:literal_i64)
    end
  end

  describe "edge cases" do
    it "parses empty input as empty program" do
      result = Stone::Grammar.parse("")
      statement_list = result.find_child(:statement_list)
      expect(statement_list).to be_empty
    end
  end

end
