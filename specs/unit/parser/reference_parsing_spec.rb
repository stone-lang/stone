require "stone/grammar"

RSpec.describe "Reference Parsing" do

  describe "predefined constants" do
    it "parses ZERO constant" do
      expect("ZERO").to parse_as(:reference)
    end

    it "parses ONE constant" do
      expect("ONE").to parse_as(:reference)
    end
  end

  describe "identifier naming rules" do
    it "parses uppercase identifiers" do
      expect("FOO").to parse_as(:reference)
    end

    it "parses lowercase identifiers" do
      expect("foo").to parse_as(:reference)
    end

    it "parses mixed case identifiers" do
      expect("fooBar").to parse_as(:reference)
    end

    it "parses identifiers with underscores" do
      expect("max_value").to parse_as(:reference)
    end

    it "parses identifiers with digits" do
      expect("value123").to parse_as(:reference)
    end

    it "allows identifiers starting with underscore" do
      expect("_private").to parse_as(:reference)
    end

    it "allows single letter identifiers" do
      expect("x").to parse_as(:reference)
    end
  end

  describe "distinguishing from literals" do
    it "parses integer literals correctly" do
      expect("0").to parse_as(:literal_i64)
    end
  end

end
# rubocop:enable RSpec/DescribeClass
