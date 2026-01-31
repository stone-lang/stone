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
    it "returns false when no module is set" do
      expect(context.record_type?("Point")).to be false
    end

    # rubocop:disable RSpec/VerifiedDoubles -- LLVM::Module extensions aren't verifiable
    it "delegates to module when module is set" do
      mod = double("LLVM::Module", record_type?: true)
      context_with_mod = described_class.new(mod)
      expect(context_with_mod.record_type?("Point")).to be true
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end

  describe "#record_definition" do
    it "returns nil when no module is set" do
      expect(context.record_definition("Point")).to be_nil
    end

    # rubocop:disable RSpec/VerifiedDoubles -- LLVM::Module extensions aren't verifiable
    it "delegates to module when module is set" do
      record_def = double("RecordDefinition")
      mod = double("LLVM::Module", record_types: {"Point" => record_def})
      context_with_mod = described_class.new(mod)
      expect(context_with_mod.record_definition("Point")).to eq(record_def)
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end

end
