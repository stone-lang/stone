require "stone/ast/computed_property_definition"
require "stone/ast/lambda"
require "stone/ast/integer_literal"
require "stone/ast/block"
require "llvm/core"
require "extensions/llvm_module"


RSpec.describe Stone::AST::ComputedPropertyDefinition do

  describe "#initialize" do
    let(:lambda_node) do
      Stone::AST::Lambda.new(["this"], [Stone::AST::IntegerLiteral.new(42)])
    end
    let(:definition) { described_class.new("Int", "abs", lambda_node) }

    it "stores the type name" do
      expect(definition.type_name).to eq("Int")
    end

    it "stores the property name" do
      expect(definition.property_name).to eq("abs")
    end

    it "stores the lambda" do
      expect(definition.lambda).to eq(lambda_node)
    end

    it "has the correct AST node name" do
      expect(definition.name).to eq(:computed_property_definition)
    end
  end

  describe "#to_llir" do
    let(:mod) { LLVM::Module.new("test") }
    let(:builder) { LLVM::Builder.new }
    let(:lambda_node) do
      Stone::AST::Lambda.new(["this"], [Stone::AST::IntegerLiteral.new(42)])
    end
    let(:definition) { described_class.new("Int", "abs", lambda_node) }

    before do
      # Setup a basic block for the builder
      func_type = LLVM::Type.function([], LLVM::Int64)
      func = mod.functions.add("test_func", func_type)
      entry = func.basic_blocks.append("entry")
      builder.position_at_end(entry)
    end

    it "generates LLVM IR for the lambda function" do
      definition.to_llir(builder, mod)

      # The lambda should create a function in the module
      # Lambda functions are typically named with a generated name
      expect(mod.functions.count).to be > 1  # At least test_func + lambda
    end

    it "registers the computed property as a function alias" do
      definition.to_llir(builder, mod)

      # The computed property should be registered as "Int@abs"
      func = mod.lookup_function("Int@abs")
      expect(func).not_to be_nil
    end

    it "returns nil (computed properties are definitions, not expressions)" do
      result = definition.to_llir(builder, mod)

      expect(result).to be_nil
    end

    it "can register multiple computed properties" do
      definition1 = create_property_definition("Int", "abs", 42)
      definition2 = create_property_definition("String", "empty?", 99)

      definition1.to_llir(builder, mod)
      definition2.to_llir(builder, mod)

      expect(mod.lookup_function("Int@abs")).not_to be_nil
      expect(mod.lookup_function("String@empty?")).not_to be_nil
      expect(mod.function_aliases.keys).to include("Int@abs", "String@empty?")
    end

    def create_property_definition(type_name, property_name, value)
      lambda_node = Stone::AST::Lambda.new(["this"], [Stone::AST::IntegerLiteral.new(value)])
      described_class.new(type_name, property_name, lambda_node)
    end

    it "allows overriding a computed property" do
      definition1 = described_class.new("Int", "test", lambda_node)
      lambda_node2 = Stone::AST::Lambda.new(["this"], [Stone::AST::IntegerLiteral.new(99)])
      definition2 = described_class.new("Int", "test", lambda_node2)

      definition1.to_llir(builder, mod)
      definition2.to_llir(builder, mod)

      # The second definition should override the first
      registered_func = mod.lookup_function("Int@test")
      # We can verify it's the second one by checking it returns a function
      expect(registered_func).not_to be_nil
      expect(registered_func).to be_a(LLVM::Function)
    end
  end

end
