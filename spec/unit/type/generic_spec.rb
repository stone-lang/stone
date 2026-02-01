require "stone"

RSpec.describe Stone::Type::Generic do
  let(:record_def) { Stone::AST::RecordDefinition.new([Stone::Type::Record::Field.new(name: "value", type_annotation: "T")]) }
  let(:lambda_node) { Stone::AST::Lambda.new(["T"], [record_def]) }

  let(:generic_type) { described_class.new(name: "Box", template: lambda_node) }

  describe "#initialize" do
    it "stores name and template" do
      expect(generic_type.name).to eq("Box")
      expect(generic_type.template).to eq(lambda_node)
    end

    it "extracts type_parameters from template" do
      expect(generic_type.type_parameters).to eq(["T"])
    end

    it "extracts body_template from template" do
      expect(generic_type.body_template).to eq(record_def)
    end

    it "raises if template does not end with RecordDefinition" do
      bad_lambda = Stone::AST::Lambda.new(["T"], [Stone::AST::IntegerLiteral.new(42)])
      expect { described_class.new(name: "Bad", template: bad_lambda) }.to raise_error(
        ArgumentError, /generic type template must end with a RecordDefinition/
      )
    end
  end

  describe "#generic?" do
    it "returns true" do
      expect(generic_type.generic?).to be true
    end

    it "returns false for non-generic types" do
      expect(Stone::Type::Int.generic?).to be false
    end
  end

  describe "#specialize" do
    it "creates a specialized RecordDefinition" do
      specialized = generic_type.specialize(["Int"])
      expect(specialized).to be_a(Stone::AST::RecordDefinition)
      expect(specialized.assigned_name).to eq("Box(Int)")
    end

    it "substitutes type parameters in fields" do
      specialized = generic_type.specialize(["Int"])
      expect(specialized.field_types).to eq(["Int"])
    end

    it "raises on wrong number of type arguments" do
      expect { generic_type.specialize(%w[Int String]) }.to raise_error(
        Stone::TypeError, /wrong number of type arguments for Box/
      )
    end
  end

  describe "#canonical_name" do
    it "formats name with type arguments" do
      expect(generic_type.canonical_name(["Int"])).to eq("Box(Int)")
    end

    it "formats multiple type arguments" do
      pair_record = Stone::AST::RecordDefinition.new([
        Stone::Type::Record::Field.new(name: "first", type_annotation: "A"),
        Stone::Type::Record::Field.new(name: "second", type_annotation: "B")
      ])
      pair_lambda = Stone::AST::Lambda.new(%w[A B], [pair_record])
      pair_generic = described_class.new(name: "Pair", template: pair_lambda)
      expect(pair_generic.canonical_name(%w[Int String])).to eq("Pair(Int, String)")
    end
  end

  describe "predicate methods" do
    it "returns false for primitive?" do
      expect(generic_type.primitive?).to be false
    end

    it "returns false for record?" do
      expect(generic_type.record?).to be false
    end

    it "returns false for function?" do
      expect(generic_type.function?).to be false
    end
  end
end
