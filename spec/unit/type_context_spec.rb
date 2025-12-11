require "stone/type_context"
require "stone/types"

RSpec.describe Stone::TypeContext do

  let(:context) { described_class.new }

  describe "#bind" do
    it "stores a type binding for a variable" do
      context.bind("x", Stone::Type::Int)
      expect(context.lookup("x")).to eq(Stone::Type::Int)
    end

    it "allows binding multiple variables" do
      context.bind("x", Stone::Type::Int)
      context.bind("y", Stone::Type::Bool)
      expect(context.lookup("x")).to eq(Stone::Type::Int)
      expect(context.lookup("y")).to eq(Stone::Type::Bool)
    end

    it "overwrites previous binding for same variable" do
      context.bind("x", Stone::Type::Int)
      context.bind("x", Stone::Type::String)
      expect(context.lookup("x")).to eq(Stone::Type::String)
    end
  end

  describe "#lookup" do
    it "returns nil for unknown variable" do
      expect(context.lookup("unknown")).to be_nil
    end

    it "returns the bound type for known variable" do
      context.bind("x", Stone::Type::Int)
      expect(context.lookup("x")).to eq(Stone::Type::Int)
    end
  end

  describe "#with_llvm_module" do
    it "creates a new context with module reference" do
      mod = instance_double(LLVM::Module)
      new_context = context.with_llvm_module(mod)
      expect(new_context).to be_a(Stone::TypeContext)
      expect(new_context.llvm_module).to eq(mod)
    end
  end

  describe "#record_type?" do
    it "returns false when no module is set" do
      expect(context.record_type?("Point")).to be false
    end

    it "delegates to module when module is set" do
      mod = instance_double(LLVM::Module, record_type?: true)
      context_with_mod = described_class.new(mod)
      expect(context_with_mod.record_type?("Point")).to be true
    end
  end

  describe "#record_definition" do
    it "returns nil when no module is set" do
      expect(context.record_definition("Point")).to be_nil
    end

    it "delegates to module when module is set" do
      record_def = instance_double(Stone::AST::RecordDefinition)
      mod = instance_double(LLVM::Module, record_types: {"Point" => record_def})
      context_with_mod = described_class.new(mod)
      expect(context_with_mod.record_definition("Point")).to eq(record_def)
    end
  end

end
