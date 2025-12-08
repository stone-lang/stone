require "stone/grammar"

RSpec.describe "Type Declaration Parsing" do

  describe "basic type declarations" do
    it "parses simple type declaration" do
      expect("x :: Integer").to parse_as(:type_declaration)
    end

    it "parses type declaration with different identifier names" do
      expect("value :: String").to parse_as(:type_declaration)
    end

    it "parses type declaration with uppercase identifier" do
      expect("MAX_VALUE :: Integer").to parse_as(:type_declaration)
    end

    it "parses type declaration with mixed case identifier" do
      expect("myVar :: Boolean").to parse_as(:type_declaration)
    end
  end

  describe "type annotations" do
    it "parses Integer type annotation" do
      expect("x :: Integer").to parse_as(:type_annotation)
    end

    it "parses String type annotation" do
      expect("x :: String").to parse_as(:type_annotation)
    end

    it "parses Boolean type annotation" do
      expect("x :: Boolean").to parse_as(:type_annotation)
    end

    it "parses custom type annotation" do
      expect("x :: CustomType").to parse_as(:type_annotation)
    end
  end

  describe "whitespace handling" do
    it "requires whitespace before ::" do
      expect("x:: Integer").not_to parse_as(:type_declaration)
    end

    it "requires whitespace after ::" do
      expect("x ::Integer").not_to parse_as(:type_declaration)
    end

    it "allows multiple spaces before ::" do
      expect("x   :: Integer").to parse_as(:type_declaration)
    end

    it "allows multiple spaces after ::" do
      expect("x ::   Integer").to parse_as(:type_declaration)
    end

    it "allows tabs as whitespace" do
      expect("x\t::\tInteger").to parse_as(:type_declaration)
    end
  end

  describe "as part of expressions" do
    it "parses type declaration as an expression" do
      expect("x :: Integer").to parse_as(:expression)
    end

    it "parses type declaration in statement" do
      expect("x :: Integer").to parse_as(:statement)
    end
  end

  describe "invalid type declarations" do
    it "does not parse without whitespace" do
      expect("x::Integer").not_to parse_as(:type_declaration)
    end

    it "does not parse with only left whitespace" do
      expect("x ::Integer").not_to parse_as(:type_declaration)
    end

    it "does not parse with only right whitespace" do
      expect("x:: Integer").not_to parse_as(:type_declaration)
    end
  end

end
