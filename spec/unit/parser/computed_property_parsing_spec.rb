require "stone/grammar"

RSpec.describe "Computed Property Parsing" do

  describe "computed property definition identifier" do
    it "parses Type@property pattern" do
      expect("Int@abs := λ(this) { this }").to parse_as(:definition)
    end

    it "parses Type@property with predicate name" do
      expect("String@empty? := λ(this) { TRUE }").to parse_as(:definition)
    end

    it "parses Type@property with bang name" do
      expect("Array@clear! := λ(this) { this }").to parse_as(:definition)
    end

    it "parses Bool@not computed property" do
      expect("Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }").to parse_as(:definition)
    end
  end

  describe "full computed property definitions" do
    it "parses Int@abs with complete lambda implementation" do
      # NOTE: Subtraction operator not yet implemented, so this is a simplified version
      code = "Int@abs := λ(this) { if(this.negative?, { 42 }, { this }) }"
      expect(code).to parse_as(:program_unit)
    end

    it "parses String@empty? with byte_count check" do
      code = "String@empty? := λ(this) { this.byte_count == 0 }"
      expect(code).to parse_as(:program_unit)
    end

    it "parses multiple computed property definitions" do
      code = <<~STONE
        Int@abs := λ(this) { this }
        String@empty? := λ(this) { TRUE }
      STONE
      expect(code).to parse_as(:program_unit)
    end
  end

  describe "distinguishing from regular definitions" do
    it "parses regular constant definition" do
      expect("MY_CONST := 42").to parse_as(:definition)
    end

    it "parses constant with @ in the value, not name" do
      # This should parse, but the @ is in the expression, not the identifier
      expect('message := "Contact: user@example.com"').to parse_as(:definition)
    end
  end

  describe "property names" do
    it "parses property name starting with lowercase letter" do
      expect("Int@abs := λ(this) { this }").to parse_as(:definition)
    end

    it "parses property name with underscores" do
      expect("Int@to_string := λ(this) { this }").to parse_as(:definition)
    end

    it "parses property name ending with question mark" do
      expect("Int@positive? := λ(this) { TRUE }").to parse_as(:definition)
    end

    it "parses property name ending with exclamation mark" do
      expect("Array@sort! := λ(this) { this }").to parse_as(:definition)
    end
  end

  describe "type names" do
    it "parses type name starting with uppercase letter" do
      expect("String@empty? := λ(this) { TRUE }").to parse_as(:definition)
    end

    it "parses multi-word type name in PascalCase" do
      expect("MyCustomType@property := λ(this) { this }").to parse_as(:definition)
    end

    it "parses type name with numbers" do
      expect("Vec3@magnitude := λ(this) { this }").to parse_as(:definition)
    end
  end

end
