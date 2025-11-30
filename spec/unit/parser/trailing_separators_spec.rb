require "stone/grammar"

RSpec.describe "Trailing Separators" do

  describe "commas in parameter lists" do
    it "disallowed after single parameter" do
      expect("f := λ(x,) { x }").not_to parse_as(:program_unit)
    end

    it "disallowed after multiple parameters" do
      expect("f := λ(x, y,) { sum(x, y) }").not_to parse_as(:program_unit)
    end
  end

  describe "commas in argument lists" do
    it "allowed after single argument" do
      expect("sum(42,)").to parse_as(:program_unit)
    end

    it "allowed after multiple arguments" do
      expect("sum(1, 2,)").to parse_as(:program_unit)
    end
  end

  describe "statement separators" do
    it "allow trailing newline after statement" do
      expect("42\n").to parse_as(:program_unit)
    end

    it "allow trailing semicolon after statement" do
      expect("42;").to parse_as(:program_unit)
    end

    it "allow multiple trailing newlines" do
      expect("42\n\n\n").to parse_as(:program_unit)
    end

    it "allow trailing semicolon and newline" do
      expect("42;\n").to parse_as(:program_unit)
    end
  end

  describe "statement separator combinations" do
    it "allow semicolon between statements" do
      expect("x := 1; y := 2").to parse_as(:program_unit)
    end

    it "allow semicolon followed by newline" do
      expect("x := 1;\ny := 2").to parse_as(:program_unit)
    end

    it "allow newline followed by semicolon on next line" do
      expect("x := 1\n; y := 2").to parse_as(:program_unit)
    end

    it "allow multiple semicolons" do
      expect("x := 1;; y := 2").to parse_as(:program_unit)
    end

    it "allow multiple trailing semicolons" do
      expect("42;;").to parse_as(:program_unit)
    end
  end

end
