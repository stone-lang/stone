require "stone"

RSpec.describe "Computed Property Transform" do

  describe "transforming Type@property to ComputedPropertyDefinition" do
    it "transforms Int@abs to ComputedPropertyDefinition" do
      code = "Int@abs := λ(this) { this }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition).to be_a(Stone::AST::ComputedPropertyDefinition)
      expect(definition.type_name).to eq("Int")
      expect(definition.property_name).to eq("abs")
      expect(definition.lambda).to be_a(Stone::AST::Lambda)
    end

    it "transforms String@empty? to ComputedPropertyDefinition" do
      code = "String@empty? := λ(this) { TRUE }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition).to be_a(Stone::AST::ComputedPropertyDefinition)
      expect(definition.type_name).to eq("String")
      expect(definition.property_name).to eq("empty?")
    end

    it "transforms Bool@not to ComputedPropertyDefinition" do
      code = "Bool@not := λ(this) { FALSE }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition).to be_a(Stone::AST::ComputedPropertyDefinition)
      expect(definition.type_name).to eq("Bool")
      expect(definition.property_name).to eq("not")
    end

    it "preserves the lambda parameters and body" do
      # NOTE: Using simplified version without subtraction operator
      code = "Int@abs := λ(this) { if(this.negative?, { 42 }, { this }) }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition.lambda.parameters).to eq(["this"])
      expect(definition.lambda.block).not_to be_nil
      expect(definition.lambda.block.statements).not_to be_empty
    end

    it "handles property names with underscores" do
      code = "Int@to_string := λ(this) { this }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition.type_name).to eq("Int")
      expect(definition.property_name).to eq("to_string")
    end

    it "handles property names ending with !" do
      code = "Array@sort! := λ(this) { this }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition.type_name).to eq("Array")
      expect(definition.property_name).to eq("sort!")
    end

    it "handles multi-word type names" do
      code = "MyCustomType@my_property := λ(this) { this }"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition.type_name).to eq("MyCustomType")
      expect(definition.property_name).to eq("my_property")
    end
  end

  describe "transforming regular definitions" do
    it "transforms regular constants to ConstantDefinition" do
      code = "MY_CONST := 42"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition).to be_a(Stone::AST::ConstantDefinition)
      expect(definition).not_to be_a(Stone::AST::ComputedPropertyDefinition)
    end

    it "handles identifiers without @ as constants" do
      code = "x := 42"
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)
      definition = ast.children.first

      expect(definition).to be_a(Stone::AST::ConstantDefinition)
    end
  end

  describe "mixed definitions" do
    it "transforms both computed properties and constants" do
      code = <<~STONE
        MY_CONST := 42
        Int@abs := λ(this) { this }
        another := 99
      STONE
      parse_tree = Stone.parse(code)
      ast = Stone.transform(parse_tree)

      expect(ast.children[0]).to be_a(Stone::AST::ConstantDefinition)
      expect(ast.children[1]).to be_a(Stone::AST::ComputedPropertyDefinition)
      expect(ast.children[2]).to be_a(Stone::AST::ConstantDefinition)
    end
  end

end
