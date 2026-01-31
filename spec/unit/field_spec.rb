require "stone"

RSpec.describe Stone::Type::Record::Field do
  describe "#initialize" do
    it "stores name and type_annotation" do
      field = described_class.new(name: "x", type_annotation: "Int")
      expect(field.name).to eq("x")
      expect(field.type_annotation).to eq("Int")
    end

    it "derives type_name from type_annotation" do
      field = described_class.new(name: "x", type_annotation: "Int")
      expect(field.type_name).to eq("Int")
    end

    it "allows explicit type_name override" do
      field = described_class.new(name: "x", type_annotation: "Int", type_name: "Integer")
      expect(field.type_name).to eq("Integer")
    end
  end

  describe "#union_annotation?" do
    it "returns false for simple type annotations" do
      field = described_class.new(name: "x", type_annotation: "Int")
      expect(field.union_annotation?).to be false
    end

    it "returns true for UnionTypeAnnotation" do
      annotation = Stone::AST::UnionTypeAnnotation.new(%w[Int Null])
      field = described_class.new(name: "x", type_annotation: annotation)
      expect(field.union_annotation?).to be true
    end
  end

  describe "#resolve_type" do
    it "resolves registered type by name" do
      field = described_class.new(name: "x", type_annotation: "Int")
      expect(field.resolve_type).to eq(Stone::Type::Int)
    end

    it "uses to_type when annotation responds to it" do
      annotation = double(:type_annotation, to_type: Stone::Type::Bool) # rubocop:disable RSpec/VerifiedDoubles
      field = described_class.new(name: "flag", type_annotation: annotation)
      expect(field.resolve_type).to eq(Stone::Type::Bool)
    end
  end

  describe "#==" do
    it "considers fields with same name and type_name equal" do
      a = described_class.new(name: "x", type_annotation: "Int")
      b = described_class.new(name: "x", type_annotation: "Int")
      expect(a).to eq(b)
    end

    it "considers fields with different names not equal" do
      a = described_class.new(name: "x", type_annotation: "Int")
      b = described_class.new(name: "y", type_annotation: "Int")
      expect(a).not_to eq(b)
    end

    it "considers fields with different types not equal" do
      a = described_class.new(name: "x", type_annotation: "Int")
      b = described_class.new(name: "x", type_annotation: "Bool")
      expect(a).not_to eq(b)
    end
  end

  describe "#hash" do
    it "produces equal hashes for equal fields" do
      a = described_class.new(name: "x", type_annotation: "Int")
      b = described_class.new(name: "x", type_annotation: "Int")
      expect(a.hash).to eq(b.hash)
    end
  end

  describe "#to_s" do
    it "formats as name :: type_name" do
      field = described_class.new(name: "age", type_annotation: "Int")
      expect(field.to_s).to eq("age :: Int")
    end
  end

  describe "#inspect" do
    it "includes class name and field details" do
      field = described_class.new(name: "age", type_annotation: "Int")
      expect(field.inspect).to eq("#<Stone::Type::Record::Field age :: Int>")
    end
  end
end
