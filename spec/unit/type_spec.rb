require "stone/type"
require "stone/types"


RSpec.describe Stone::Type do

  after do
    Stone::TypeRegistry.instance.reset!
    Stone::Types.bootstrap_registry!
  end

  describe ".primitive" do
    it "creates a primitive type" do
      type = described_class.primitive(name: "Int", llvm_type: :mock_llvm)
      expect(type.name).to eq("Int")
      expect(type.primitive?).to be true
      expect(type.record?).to be false
    end

    it "accepts property_types" do
      bool_type = described_class.primitive(name: "Bool", llvm_type: :mock)
      type = described_class.primitive(
        name: "Int",
        llvm_type: :mock,
        property_types: {"positive?" => bool_type}
      )
      expect(type.property_return_type("positive?")).to eq(bool_type)
    end

    it "accepts min and max bounds" do
      type = described_class.primitive(
        name: "Int",
        llvm_type: :mock,
        min: -100,
        max: 100
      )
      expect(type.min).to eq(-100)
      expect(type.max).to eq(100)
    end

    it "defaults min and max to nil" do
      type = described_class.primitive(name: "Bool", llvm_type: :mock)
      expect(type.min).to be_nil
      expect(type.max).to be_nil
    end
  end

  describe ".record" do
    it "creates a record type" do
      fields = [{name: "x", type: "Int"}, {name: "y", type: "Int"}]
      type = described_class.record(name: "Point", fields:, llvm_type: :mock)
      expect(type.name).to eq("Point")
      expect(type.primitive?).to be false
      expect(type.record?).to be true
      expect(type.fields).to eq(fields)
    end
  end

  describe ".function" do
    let(:int_type) { Stone::Type::Int }
    let(:bool_type) { Stone::Type::Bool }
    let(:string_type) { Stone::Type::String }

    it "creates a function type with param and return types" do
      type = described_class.function(param_types: [int_type, int_type], return_type: int_type)
      expect(type.param_types).to eq([int_type, int_type])
      expect(type.return_type).to eq(int_type)
    end

    it "generates name from param and return types" do
      type = described_class.function(param_types: [int_type, int_type], return_type: int_type)
      expect(type.name).to eq("(Int, Int) -> Int")
    end

    it "handles single parameter" do
      type = described_class.function(param_types: [string_type], return_type: bool_type)
      expect(type.name).to eq("(String) -> Bool")
    end

    it "handles no parameters" do
      type = described_class.function(param_types: [], return_type: int_type)
      expect(type.name).to eq("() -> Int")
    end

    it "wraps function return type in parentheses" do
      inner = described_class.function(param_types: [int_type], return_type: int_type)
      outer = described_class.function(param_types: [int_type], return_type: inner)
      expect(outer.name).to eq("(Int) -> ((Int) -> Int)")
    end

    it "is not primitive" do
      type = described_class.function(param_types: [int_type], return_type: int_type)
      expect(type.primitive?).to be false
    end

    it "is not a record" do
      type = described_class.function(param_types: [int_type], return_type: int_type)
      expect(type.record?).to be false
    end

    it "is a function" do
      type = described_class.function(param_types: [int_type], return_type: int_type)
      expect(type.function?).to be true
    end

    it "primitives are not functions" do
      expect(int_type.function?).to be false
    end

    it "records are not functions" do
      record = described_class.record(name: "Point", fields: [], llvm_type: :mock)
      expect(record.function?).to be false
    end
  end

  describe "#==" do
    it "returns true for types with same name" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type1).to eq(type2)
    end

    it "returns false for types with different names" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Bool", llvm_type: :mock)
      expect(type1).not_to eq(type2)
    end

    it "returns false when compared with non-Type object" do
      type = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type).not_to eq("Int")
      expect(type).not_to be_nil
    end

    it "considers only name for equality (different llvm_type)" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock1)
      type2 = described_class.primitive(name: "Int", llvm_type: :mock2)
      expect(type1).to eq(type2)
    end
  end

  describe "#hash and #eql?" do
    it "can be used as hash keys" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Int", llvm_type: :mock)
      hash = {type1 => "value"}
      expect(hash[type2]).to eq("value")
    end

    it "produces same hash for equal types" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type1.hash).to eq(type2.hash)
    end

    it "produces different hash for different types" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Bool", llvm_type: :mock)
      expect(type1.hash).not_to eq(type2.hash)
    end

    it "eql? is aliased to ==" do
      type1 = described_class.primitive(name: "Int", llvm_type: :mock)
      type2 = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type1.eql?(type2)).to be true
    end
  end

  describe "#to_s" do
    it "returns the type name" do
      type = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type.to_s).to eq("Int")
    end
  end

  describe "#as_String" do
    it "returns the type name" do
      type = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type.as_String).to eq("Int")
    end
  end

  describe "#inspect" do
    it "returns a readable representation" do
      type = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type.inspect).to eq("#<Stone::Type:Int>")
    end
  end

  describe "built-in type constants" do
    it "provides Stone::Type::Int" do
      expect(Stone::Type::Int).to be_a(Stone::Type)
      expect(Stone::Type::Int.name).to eq("Int")
    end

    it "provides Stone::Type::Bool" do
      expect(Stone::Type::Bool).to be_a(Stone::Type)
      expect(Stone::Type::Bool.name).to eq("Bool")
    end

    it "provides Stone::Type::String" do
      expect(Stone::Type::String).to be_a(Stone::Type)
      expect(Stone::Type::String.name).to eq("String")
    end

    it "provides Stone::Type::Type" do
      expect(Stone::Type::Type).to be_a(Stone::Type)
      expect(Stone::Type::Type.name).to eq("Type")
    end

    it "provides Stone::Type::Int with min and max bounds" do
      expect(Stone::Type::Int.min).to eq(-(2**63))
      expect(Stone::Type::Int.max).to eq(2**63 - 1)
    end
  end

  describe "Stone::Type::Registry" do
    it "is the TypeRegistry singleton" do
      expect(Stone::Type::Registry).to eq(Stone::TypeRegistry.instance)
    end

    it "can look up types by name" do
      expect(Stone::Type::Registry["Int"]).to eq(Stone::Type::Int)
    end

    it "can register a type under a custom name" do
      func_type = Stone::Type.function(param_types: [Stone::Type::Int], return_type: Stone::Type::Bool)
      Stone::Type::Registry.register_as("even?", func_type)
      expect(Stone::Type::Registry["even?"]).to eq(func_type)
    end
  end

  describe "backward compatibility" do
    it "provides Stone::TypeInstance as alias for Stone::Type" do
      expect(Stone::TypeInstance).to eq(Stone::Type)
    end

    it "allows creating types through the alias" do
      type = Stone::TypeInstance.primitive(name: "Test", llvm_type: :mock)
      expect(type).to be_a(Stone::Type)
    end
  end

end
