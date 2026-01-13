require "stone/grammar"

RSpec.describe "Function Type Parsing" do

  describe "valid function types" do
    it "parses simple function type" do
      expect("f :: (Int) -> Int").to parse_as(:type_declaration)
    end

    it "parses multi-parameter function type" do
      expect("f :: (Int, Int) -> Bool").to parse_as(:type_declaration)
    end

    it "parses zero-parameter function type" do
      expect("f :: () -> Int").to parse_as(:type_declaration)
    end

    it "parses function type with three parameters" do
      expect("f :: (Int, String, Bool) -> Int").to parse_as(:type_declaration)
    end

    it "parses nested function type with explicit parens" do
      expect("f :: (Int) -> ((Int) -> Int)").to parse_as(:type_declaration)
    end

    it "parses deeply nested function type" do
      expect("f :: (Int) -> ((Int) -> ((Int) -> Int))").to parse_as(:type_declaration)
    end

    it "parses function taking function as parameter" do
      expect("f :: ((Int) -> Int) -> Int").to parse_as(:type_declaration)
    end

    it "parses function with function parameter and function return" do
      expect("f :: ((Int) -> Int) -> ((Int) -> Int)").to parse_as(:type_declaration)
    end
  end

  describe "invalid function types" do
    it "rejects unparenthesized params" do
      expect("f :: Int -> Int").not_to parse_as(:type_declaration)
    end

    it "rejects unparenthesized nested return" do
      expect("f :: (Int) -> (Int) -> Int").not_to parse_as(:type_declaration)
    end
  end

  describe "function types in type_annotation rule" do
    it "parses function type as type_annotation" do
      expect("f :: (Int) -> Int").to parse_as(:type_annotation)
    end

    it "parses function type with function type parameter" do
      expect("f :: ((Int) -> Bool, Int) -> Int").to parse_as(:type_annotation)
    end
  end

  describe "whitespace handling" do
    it "allows no space around arrow" do
      expect("f :: (Int)->Int").to parse_as(:type_declaration)
    end

    it "allows spaces around arrow" do
      expect("f :: (Int) -> Int").to parse_as(:type_declaration)
    end

    it "allows extra spaces around arrow" do
      expect("f :: (Int)   ->   Int").to parse_as(:type_declaration)
    end

    it "allows space after opening paren" do
      expect("f :: ( Int) -> Int").to parse_as(:type_declaration)
    end

    it "allows space before closing paren" do
      expect("f :: (Int ) -> Int").to parse_as(:type_declaration)
    end
  end

end
