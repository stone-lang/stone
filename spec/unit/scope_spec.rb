require "stone/scope"


RSpec.describe Stone::Scope do

  describe "basic operations" do
    it "creates an empty scope" do
      scope = described_class.new
      expect(scope.parent).to be_nil
      expect(scope.top_level?).to be true
    end

    it "defines and looks up values" do
      scope = described_class.new
      scope.define("x", value: 42)

      definition = scope.lookup("x")
      expect(definition[:value]).to eq(42)
    end

    it "returns nil for undefined names" do
      scope = described_class.new
      expect(scope.lookup("unknown")).to be_nil
    end

    it "tracks source locations" do
      scope = described_class.new
      location = {line: 1, column: 5}
      scope.define("x", value: 42, location: location)

      definition = scope.lookup("x")
      expect(definition[:location]).to eq(location)
    end

    it "checks if a name is defined locally" do
      scope = described_class.new
      scope.define("x", value: 42)

      expect(scope.defined_locally?("x")).to be true
      expect(scope.defined_locally?("y")).to be false
    end

    it "overwrites existing definition when redefined in same scope" do
      scope = described_class.new
      scope.define("x", value: 1)
      scope.define("x", value: 2)

      expect(scope.lookup("x")[:value]).to eq(2)
    end
  end

  describe "nested scopes" do
    it "creates child scopes" do
      parent = described_class.new
      child = parent.child

      expect(child.parent).to eq(parent)
      expect(child.depth).to eq(1)
    end

    it "looks up through parent chain" do
      parent = described_class.new
      parent.define("x", value: 42)

      child = parent.child
      definition = child.lookup("x")

      expect(definition[:value]).to eq(42)
    end

    it "shadows parent definitions" do
      parent = described_class.new
      parent.define("x", value: 1)

      child = parent.child
      child.define("x", value: 2)

      expect(child.lookup("x")[:value]).to eq(2)
      expect(parent.lookup("x")[:value]).to eq(1)
    end

    it "distinguishes local from inherited definitions" do
      parent = described_class.new
      parent.define("x", value: 1)

      child = parent.child

      expect(child.defined_locally?("x")).to be false
      expect(child.lookup("x")).not_to be_nil
    end

    it "looks up only in local scope when requested" do
      parent = described_class.new
      parent.define("x", value: 1)

      child = parent.child

      expect(child.lookup_local("x")).to be_nil
      expect(child.lookup("x")).not_to be_nil
    end

    it "calculates depth correctly for deeply nested scopes" do
      scope = described_class.new
      expect(scope.depth).to eq(0)

      child = scope.child
      expect(child.depth).to eq(1)

      grandchild = child.child
      expect(grandchild.depth).to eq(2)
    end

    it "looks up through multiple levels of parents" do
      grandparent = described_class.new
      grandparent.define("x", value: 1)

      parent = grandparent.child
      parent.define("y", value: 2)

      child = parent.child

      expect(child.lookup("x")[:value]).to eq(1)
      expect(child.lookup("y")[:value]).to eq(2)
      expect(child.lookup("z")).to be_nil
    end
  end

  describe "type declarations" do
    it "declares and looks up types" do
      scope = described_class.new
      location = {line: 1, column: 1}
      scope.declare_type("x", type_annotation: "Int", location: location)

      expect(scope.declared_type("x")).to eq("Int")
      expect(scope.type_declaration_location("x")).to eq(location)
    end

    it "looks up type declarations through parent chain" do
      parent = described_class.new
      parent.declare_type("x", type_annotation: "Int")

      child = parent.child
      expect(child.declared_type("x")).to eq("Int")
    end

    it "shadows parent type declarations" do
      parent = described_class.new
      parent.declare_type("x", type_annotation: "Int")

      child = parent.child
      child.declare_type("x", type_annotation: "String")

      expect(child.declared_type("x")).to eq("String")
      expect(parent.declared_type("x")).to eq("Int")
    end

    it "returns nil for undeclared types" do
      scope = described_class.new
      expect(scope.declared_type("unknown")).to be_nil
      expect(scope.type_declaration_location("unknown")).to be_nil
    end

    it "checks if type is declared locally" do
      parent = described_class.new
      parent.declare_type("x", type_annotation: "Int")

      child = parent.child

      expect(parent.type_declared_locally?("x")).to be true
      expect(child.type_declared_locally?("x")).to be false
    end
  end

  describe "#lookup_type" do
    it "returns name for built-in types" do
      scope = described_class.new
      expect(scope.lookup_type("Int")).to eq("Int")
      expect(scope.lookup_type("Bool")).to eq("Bool")
      expect(scope.lookup_type("String")).to eq("String")
      expect(scope.lookup_type("Type")).to eq("Type")
      expect(scope.lookup_type("Null")).to eq("Null")
    end

    it "returns nil for unknown types" do
      scope = described_class.new
      expect(scope.lookup_type("Unknown")).to be_nil
    end

    it "finds types through type declarations" do
      scope = described_class.new
      scope.declare_type("MyType", type_annotation: "Int")
      expect(scope.lookup_type("MyType")).to eq("MyType")
    end

    it "finds types through definitions" do
      scope = described_class.new
      scope.define("T", value: :type_parameter)
      expect(scope.lookup_type("T")).to eq("T")
    end

    it "finds types through parent chain" do
      parent = described_class.new
      parent.define("T", value: :type_parameter)
      child = parent.child
      expect(child.lookup_type("T")).to eq("T")
    end

    it "inner scope shadows outer scope" do
      parent = described_class.new
      parent.define("T", value: :outer)
      child = parent.child
      child.define("T", value: :inner)
      expect(child.lookup_type("T")).to eq("T")
    end
  end

  describe "top-level scope" do
    before do described_class.reset_top_level! end
    after do described_class.reset_top_level! end

    it "returns the same instance" do
      expect(described_class.top_level).to equal(described_class.top_level)
    end

    it "is a top-level scope" do
      expect(described_class.top_level.top_level?).to be true
    end

    it "has depth of zero" do
      expect(described_class.top_level.depth).to eq(0)
    end

    it "can be reset for testing" do
      first = described_class.top_level
      first.define("x", value: 42)

      described_class.reset_top_level!

      second = described_class.top_level
      expect(second).not_to equal(first)
      expect(second.lookup("x")).to be_nil
    end
  end

end
