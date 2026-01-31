require "stone/type"
require "stone/type_registry"
require "stone/types"


RSpec.describe Stone::TypeRegistry do

  let(:registry) { described_class.instance }

  before do
    registry.reset!
  end

  after do
    registry.reset!
    Stone::Types.bootstrap_registry!
  end

  describe "#register" do
    it "registers a type" do
      type = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(type)
      expect(registry.lookup("Int")).to eq(type)
    end

    it "returns the registered type" do
      type = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      expect(registry.register(type)).to eq(type)
    end
  end

  describe "#lookup" do
    it "returns nil for unregistered types" do
      expect(registry.lookup("Unknown")).to be_nil
    end

    it "returns registered type" do
      type = Stone::Type.primitive(name: "Bool", llvm_type: :mock)
      registry.register(type)
      expect(registry.lookup("Bool")).to eq(type)
    end
  end

  describe "#[]" do
    it "is an alias for lookup" do
      type = Stone::Type.primitive(name: "String", llvm_type: :mock)
      registry.register(type)
      expect(registry["String"]).to eq(type)
    end
  end

  describe "#registered?" do
    it "returns false for unregistered types" do
      expect(registry.registered?("Foo")).to be false
    end

    it "returns true for registered types" do
      type = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(type)
      expect(registry.registered?("Int")).to be true
    end
  end

  describe "#record?" do
    it "returns false for primitives" do
      type = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(type)
      expect(registry.record?("Int")).to be false
    end

    it "returns true for records" do
      type = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(type)
      expect(registry.record?("Point")).to be true
    end

    it "returns false for unregistered types" do
      expect(registry.record?("Unknown")).to be false
    end
  end

  describe "#primitives" do
    it "returns only primitive types" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      point = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(int)
      registry.register(point)
      expect(registry.primitives).to eq([int])
    end
  end

  describe "#records" do
    it "returns only record types" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      point = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(int)
      registry.register(point)
      expect(registry.records).to eq([point])
    end
  end

  describe "#reset_to_bootstrap!" do
    it "retains types registered before the first call" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      bool = Stone::Type.primitive(name: "Bool", llvm_type: :mock)
      registry.register(int)
      registry.register(bool)
      registry.reset_to_bootstrap!
      expect(registry.lookup("Int")).to eq(int)
      expect(registry.lookup("Bool")).to eq(bool)
    end

    it "removes types registered after the first call" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(int)
      registry.reset_to_bootstrap!

      point = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(point)
      expect(registry.lookup("Point")).to eq(point)

      registry.reset_to_bootstrap!
      expect(registry.lookup("Point")).to be_nil
    end

    it "preserves bootstrap types across multiple resets" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(int)
      registry.reset_to_bootstrap!

      registry.register(Stone::Type.record(name: "Foo", fields: [], llvm_type: :mock))
      registry.reset_to_bootstrap!

      registry.register(Stone::Type.record(name: "Bar", fields: [], llvm_type: :mock))
      registry.reset_to_bootstrap!

      expect(registry.lookup("Int")).to eq(int)
      expect(registry.lookup("Foo")).to be_nil
      expect(registry.lookup("Bar")).to be_nil
    end

    it "establishes a fresh bootstrap snapshot after reset!" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(int)
      registry.reset_to_bootstrap!

      registry.reset!

      new_base = Stone::Type.primitive(name: "NewBase", llvm_type: :mock)
      registry.register(new_base)
      registry.reset_to_bootstrap!

      expect(registry.lookup("NewBase")).to eq(new_base)
      expect(registry.lookup("Int")).to be_nil
    end

    it "captures bootstrap snapshot only on the first call" do
      int = Stone::Type.primitive(name: "Int", llvm_type: :mock)
      registry.register(int)
      registry.reset_to_bootstrap!

      # Register a new type and reset again — the new type should NOT become part of bootstrap
      extra = Stone::Type.primitive(name: "Extra", llvm_type: :mock)
      registry.register(extra)
      registry.reset_to_bootstrap!

      expect(registry.lookup("Int")).to eq(int)
      expect(registry.lookup("Extra")).to be_nil
    end
  end

  describe "convenience accessors" do
    before do
      registry.register(Stone::Type.primitive(name: "Int", llvm_type: :mock))
      registry.register(Stone::Type.primitive(name: "Bool", llvm_type: :mock))
      registry.register(Stone::Type.primitive(name: "String", llvm_type: :mock))
      registry.register(Stone::Type.primitive(name: "Type", llvm_type: :mock))
    end

    it "#int returns Int type" do
      expect(registry.int.name).to eq("Int")
    end

    it "#bool returns Bool type" do
      expect(registry.bool.name).to eq("Bool")
    end

    it "#string returns String type" do
      expect(registry.string.name).to eq("String")
    end

    it "#type returns Type type" do
      expect(registry.type.name).to eq("Type")
    end
  end

end
