require "stone/type"


RSpec.describe Stone::TypeInstance do

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

end
