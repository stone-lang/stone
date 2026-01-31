require "stone/type_context"
require "stone/types"
require "stone/ast/record_definition"

RSpec.describe Stone::TypeContext do

  let(:context) { described_class.new }
  let(:registry) { Stone::TypeRegistry.instance }

  describe "#bind" do
    it "stores a type binding for a variable" do
      context.bind("x", registry.int)
      expect(context.lookup("x")).to eq(registry.int)
    end

    it "allows binding multiple variables" do
      context.bind("x", registry.int)
      context.bind("y", registry.bool)
      expect(context.lookup("x")).to eq(registry.int)
      expect(context.lookup("y")).to eq(registry.bool)
    end

    it "overwrites previous binding for same variable" do
      context.bind("x", registry.int)
      context.bind("x", registry.string)
      expect(context.lookup("x")).to eq(registry.string)
    end
  end

  describe "#lookup" do
    it "returns nil for unknown variable" do
      expect(context.lookup("unknown")).to be_nil
    end

    it "returns the bound type for known variable" do
      context.bind("x", registry.int)
      expect(context.lookup("x")).to eq(registry.int)
    end

    context "with scope" do
      let(:scope) { Stone::Scope.new }
      let(:context_with_scope) { described_class.new(nil, scope:) }

      it "falls back to scope's declared type when no binding exists" do
        scope.declare_type("x", type: registry.int)
        expect(context_with_scope.lookup("x")).to eq(registry.int)
      end

      it "prefers bindings over scope declarations" do
        scope.declare_type("x", type: registry.string)
        context_with_scope.bind("x", registry.int)
        expect(context_with_scope.lookup("x")).to eq(registry.int)
      end

      it "returns nil when neither binding nor scope has the name" do
        expect(context_with_scope.lookup("unknown")).to be_nil
      end
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
    it "returns false for unknown type" do
      expect(context.record_type?("UnknownRecord")).to be false
    end

    it "returns false for non-record types" do
      expect(context.record_type?("Int")).to be false
    end

    it "returns true for registered record types" do
      fields = [Stone::Type::Record::Field.new(name: "x", type_annotation: Stone::AST::TypeAnnotation.new("Int"))]
      record = Stone::Type.record(name: "CheckPoint", fields:, llvm_type: nil)
      Stone::Type::Registry.register(record)
      expect(context.record_type?("CheckPoint")).to be true
    end
  end

  describe "#record_type" do
    it "returns nil for unknown type" do
      expect(context.record_type("UnknownRecord")).to be_nil
    end

    it "returns nil for non-record types" do
      expect(context.record_type("Int")).to be_nil
    end

    it "returns the record type from Registry" do
      fields = [Stone::Type::Record::Field.new(name: "x", type_annotation: Stone::AST::TypeAnnotation.new("Int"))]
      record = Stone::Type.record(name: "TestPoint", fields:, llvm_type: nil)
      Stone::Type::Registry.register(record)
      expect(context.record_type("TestPoint")).to eq(record)
    end
  end

end
