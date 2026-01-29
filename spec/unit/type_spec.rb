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

  describe "#generic_for" do
    it "returns the generic category when set" do
      type = described_class.primitive(name: "Record", llvm_type: :mock, generic_for: :record)
      expect(type.generic_for).to eq(:record)
    end

    it "returns nil when not set" do
      type = described_class.primitive(name: "Int", llvm_type: :mock)
      expect(type.generic_for).to be_nil
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

  describe "#size_bytes" do
    it "returns 8 for Int" do
      expect(Stone::Type::Int.size_bytes).to eq(8)
    end

    it "returns 1 for Bool" do
      expect(Stone::Type::Bool.size_bytes).to eq(1)
    end

    it "returns 8 for String (pointer size)" do
      expect(Stone::Type::String.size_bytes).to eq(8)
    end

    it "returns 0 for Null" do
      expect(Stone::Type::Null.size_bytes).to eq(0)
    end

    it "returns 8 for Type (pointer size)" do
      expect(Stone::Type::Type.size_bytes).to eq(8)
    end

    context "with union types" do
      it "returns tag size plus payload size for Int | Null" do
        union = Stone::Type.union(alternatives: [Stone::Type::Int, Stone::Type::Null])
        # 8 bytes for tag pointer + 8 bytes for payload (max of Int=8, Null=0)
        expect(union.size_bytes).to eq(16)
      end

      it "returns tag size plus payload size for Bool | Null" do
        union = Stone::Type.union(alternatives: [Stone::Type::Bool, Stone::Type::Null])
        # 8 bytes for tag pointer + 1 byte for payload (max of Bool=1, Null=0)
        expect(union.size_bytes).to eq(9)
      end

      it "returns tag size plus max alternative size for Int | String" do
        union = Stone::Type.union(alternatives: [Stone::Type::Int, Stone::Type::String])
        # 8 bytes for tag pointer + 8 bytes for payload (max of Int=8, String=8)
        expect(union.size_bytes).to eq(16)
      end
    end
  end

  describe "#alignment" do
    it "returns 8 for Int" do
      expect(Stone::Type::Int.alignment).to eq(8)
    end

    it "returns 1 for Bool" do
      expect(Stone::Type::Bool.alignment).to eq(1)
    end

    it "returns 8 for String (pointer alignment)" do
      expect(Stone::Type::String.alignment).to eq(8)
    end

    it "returns 1 for Null" do
      expect(Stone::Type::Null.alignment).to eq(1)
    end

    it "returns 8 for Type (pointer alignment)" do
      expect(Stone::Type::Type.alignment).to eq(8)
    end

    context "with union types" do
      it "returns 8 for Int | Null (pointer alignment for tag)" do
        union = Stone::Type.union(alternatives: [Stone::Type::Int, Stone::Type::Null])
        expect(union.alignment).to eq(8)
      end
    end
  end

  describe "#payload_size (Union)" do
    it "returns max of alternative sizes" do
      union = Stone::Type.union(alternatives: [Stone::Type::Int, Stone::Type::Null])
      expect(union.payload_size).to eq(8)  # max(8, 0)
    end

    it "returns 1 for Bool | Null" do
      union = Stone::Type.union(alternatives: [Stone::Type::Bool, Stone::Type::Null])
      expect(union.payload_size).to eq(1)  # max(1, 0)
    end

    it "returns 8 for Int | String" do
      union = Stone::Type.union(alternatives: [Stone::Type::Int, Stone::Type::String])
      expect(union.payload_size).to eq(8)  # max(8, 8)
    end
  end

  describe "#nullable?" do
    it "returns false for primitive types" do
      expect(Stone::Type::Int.nullable?).to be false
      expect(Stone::Type::Bool.nullable?).to be false
      expect(Stone::Type::String.nullable?).to be false
    end

    it "returns false for Null type itself" do
      expect(Stone::Type::Null.nullable?).to be false
    end

    it "returns false for record types" do
      record = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      expect(record.nullable?).to be false
    end

    it "returns false for function types" do
      func = Stone::Type.function(param_types: [Stone::Type::Int], return_type: Stone::Type::Int)
      expect(func.nullable?).to be false
    end
  end

  describe "#non_null_type" do
    it "returns self for primitive types" do
      expect(Stone::Type::Int.non_null_type).to eq(Stone::Type::Int)
      expect(Stone::Type::Bool.non_null_type).to eq(Stone::Type::Bool)
    end

    it "returns self for Null type" do
      expect(Stone::Type::Null.non_null_type).to eq(Stone::Type::Null)
    end

    it "returns self for record types" do
      record = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      expect(record.non_null_type).to eq(record)
    end

    it "returns self for function types" do
      func = Stone::Type.function(param_types: [Stone::Type::Int], return_type: Stone::Type::Int)
      expect(func.non_null_type).to eq(func)
    end
  end

  describe "#compatible_with?" do
    let(:int_type) { Stone::Type::Int }
    let(:bool_type) { Stone::Type::Bool }
    let(:string_type) { Stone::Type::String }
    let(:null_type) { Stone::Type::Null }

    context "with primitive types" do
      it "returns true for same type" do
        expect(int_type.compatible_with?(int_type)).to be true
      end

      it "returns false for different types" do
        expect(int_type.compatible_with?(bool_type)).to be false
      end

      it "returns false for Null vs primitive" do
        expect(null_type.compatible_with?(int_type)).to be false
      end
    end

    context "with function types" do
      it "returns true for identical function types" do
        int_to_int = Stone::Type.function(param_types: [int_type], return_type: int_type)
        other = Stone::Type.function(param_types: [int_type], return_type: int_type)
        expect(int_to_int.compatible_with?(other)).to be true
      end

      it "returns false for different return types" do
        int_to_int = Stone::Type.function(param_types: [int_type], return_type: int_type)
        int_to_bool = Stone::Type.function(param_types: [int_type], return_type: bool_type)
        expect(int_to_int.compatible_with?(int_to_bool)).to be false
      end

      it "returns false for different param types" do
        int_to_int = Stone::Type.function(param_types: [int_type], return_type: int_type)
        bool_to_int = Stone::Type.function(param_types: [bool_type], return_type: int_type)
        expect(int_to_int.compatible_with?(bool_to_int)).to be false
      end

      it "returns false when compared with primitive" do
        int_to_int = Stone::Type.function(param_types: [int_type], return_type: int_type)
        expect(int_to_int.compatible_with?(int_type)).to be false
      end
    end

    context "with generic types" do
      it "generic Record is compatible with any record type" do
        generic_record = Stone::Type.primitive(name: "Record", llvm_type: :mock, generic_for: :record)
        point = Stone::Type.record(name: "Point", fields: [{name: "x", type: "Int"}], llvm_type: :mock)
        expect(generic_record.compatible_with?(point)).to be true
      end

      it "generic Record is not compatible with Int" do
        generic_record = Stone::Type.primitive(name: "Record", llvm_type: :mock, generic_for: :record)
        expect(generic_record.compatible_with?(int_type)).to be false
      end

      it "generic Record is compatible with itself" do
        generic_record = Stone::Type.primitive(name: "Record", llvm_type: :mock, generic_for: :record)
        expect(generic_record.compatible_with?(generic_record)).to be true
      end

      it "generic Function is compatible with any function type" do
        generic_fn = Stone::Type.primitive(name: "Function", llvm_type: :mock, generic_for: :function)
        int_to_int = Stone::Type.function(param_types: [int_type], return_type: int_type)
        expect(generic_fn.compatible_with?(int_to_int)).to be true
      end

      it "generic Function is not compatible with Int" do
        generic_fn = Stone::Type.primitive(name: "Function", llvm_type: :mock, generic_for: :function)
        expect(generic_fn.compatible_with?(int_type)).to be false
      end

      it "generic Function is compatible with itself" do
        generic_fn = Stone::Type.primitive(name: "Function", llvm_type: :mock, generic_for: :function)
        expect(generic_fn.compatible_with?(generic_fn)).to be true
      end
    end

    context "with union types" do
      it "returns true when value type is one of the alternatives" do
        int_or_string = Stone::Type.union(alternatives: [int_type, string_type])
        expect(int_or_string.compatible_with?(int_type)).to be true
        expect(int_or_string.compatible_with?(string_type)).to be true
      end

      it "returns false when value type is not an alternative" do
        int_or_string = Stone::Type.union(alternatives: [int_type, string_type])
        expect(int_or_string.compatible_with?(bool_type)).to be false
      end

      it "returns true for Null when union includes Null" do
        int_or_null = Stone::Type.union(alternatives: [int_type, null_type])
        expect(int_or_null.compatible_with?(null_type)).to be true
      end

      it "returns false for Null when union does not include Null" do
        int_or_string = Stone::Type.union(alternatives: [int_type, string_type])
        expect(int_or_string.compatible_with?(null_type)).to be false
      end

      it "returns true when both unions have compatible alternatives" do
        int_or_string = Stone::Type.union(alternatives: [int_type, string_type])
        other_union = Stone::Type.union(alternatives: [int_type, string_type])
        expect(int_or_string.compatible_with?(other_union)).to be true
      end

      it "returns false when unions have incompatible alternatives" do
        int_or_string = Stone::Type.union(alternatives: [int_type, string_type])
        bool_or_null = Stone::Type.union(alternatives: [bool_type, null_type])
        expect(int_or_string.compatible_with?(bool_or_null)).to be false
      end
    end
  end

  describe ".union" do
    let(:int_type) { Stone::Type::Int }
    let(:bool_type) { Stone::Type::Bool }
    let(:string_type) { Stone::Type::String }
    let(:null_type) { Stone::Type::Null }

    it "creates a union type with alternatives" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.alternatives).to contain_exactly(int_type, string_type)
    end

    it "raises error for empty alternatives" do
      expect { Stone::Type.union(alternatives: []) }.to raise_error(ArgumentError, /at least one alternative/)
    end

    it "normalizes single-element union to the element itself" do
      result = Stone::Type.union(alternatives: [int_type])
      expect(result).to eq(int_type)
      expect(result.union?).to be false
    end

    it "generates name from alternatives (sorted alphabetically)" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.name).to eq("Int | String")
    end

    context "with name override" do
      it "uses the provided name instead of auto-generating" do
        union = Stone::Type.union(alternatives: [int_type, string_type], name: "Foo")
        expect(union.name).to eq("Foo")
      end

      it "auto-generates name when no override is given" do
        union = Stone::Type.union(alternatives: [int_type, string_type])
        expect(union.name).to eq("Int | String")
      end

      it "preserves single-alternative union when name is given" do
        union = Stone::Type.union(alternatives: [int_type], name: "SingleAlias")
        expect(union.union?).to be true
        expect(union.name).to eq("SingleAlias")
      end

      it "still collapses single-alternative union without name override" do
        result = Stone::Type.union(alternatives: [int_type])
        expect(result).to eq(int_type)
        expect(result.union?).to be false
      end
    end

    it "handles three or more alternatives (sorted alphabetically)" do
      union = Stone::Type.union(alternatives: [int_type, string_type, bool_type])
      expect(union.name).to eq("Bool | Int | String")
    end

    it "is not primitive" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.primitive?).to be false
    end

    it "is not a record" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.record?).to be false
    end

    it "is not a function" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.function?).to be false
    end

    it "is a union" do
      union = Stone::Type.union(alternatives: [int_type, string_type])
      expect(union.union?).to be true
    end

    it "primitives are not unions" do
      expect(int_type.union?).to be false
    end

    describe "#nullable?" do
      it "returns true when Null is an alternative" do
        union = Stone::Type.union(alternatives: [int_type, null_type])
        expect(union.nullable?).to be true
      end

      it "returns false when Null is not an alternative" do
        union = Stone::Type.union(alternatives: [int_type, string_type])
        expect(union.nullable?).to be false
      end
    end

    describe "#non_null_type" do
      it "returns the single non-null type when union has two alternatives" do
        union = Stone::Type.union(alternatives: [int_type, null_type])
        expect(union.non_null_type).to eq(int_type)
      end

      it "returns a union of remaining types when more than two alternatives" do
        union = Stone::Type.union(alternatives: [int_type, string_type, null_type])
        non_null = union.non_null_type
        expect(non_null).to be_a(Stone::Type)
        expect(non_null.union?).to be true
        expect(non_null.alternatives).to contain_exactly(int_type, string_type)
      end
    end

    describe "flattening" do
      it "flattens nested unions" do
        inner = Stone::Type.union(alternatives: [int_type, string_type])
        outer = Stone::Type.union(alternatives: [inner, bool_type])
        expect(outer.alternatives).to contain_exactly(int_type, string_type, bool_type)
      end
    end

    describe "deduplication" do
      it "removes duplicate types (normalizing single-element to the type itself)" do
        result = Stone::Type.union(alternatives: [int_type, int_type])
        expect(result).to eq(int_type)
        expect(result.union?).to be false
      end

      it "removes duplicates from multiple occurrences" do
        union = Stone::Type.union(alternatives: [int_type, string_type, int_type])
        expect(union.alternatives).to contain_exactly(int_type, string_type)
      end
    end

    describe "#==" do
      it "returns true for unions with same alternatives" do
        union1 = Stone::Type.union(alternatives: [int_type, string_type])
        union2 = Stone::Type.union(alternatives: [int_type, string_type])
        expect(union1).to eq(union2)
      end

      it "returns true regardless of alternative order" do
        union1 = Stone::Type.union(alternatives: [int_type, string_type])
        union2 = Stone::Type.union(alternatives: [string_type, int_type])
        expect(union1).to eq(union2)
      end

      it "returns false for unions with different alternatives" do
        union1 = Stone::Type.union(alternatives: [int_type, string_type])
        union2 = Stone::Type.union(alternatives: [int_type, bool_type])
        expect(union1).not_to eq(union2)
      end

      it "returns false when compared with non-union" do
        union = Stone::Type.union(alternatives: [int_type, string_type])
        expect(union).not_to eq(int_type)
      end
    end

    describe "#to_s" do
      it "returns the union name" do
        union = Stone::Type.union(alternatives: [int_type, string_type])
        expect(union.to_s).to eq("Int | String")
      end
    end
  end

end
