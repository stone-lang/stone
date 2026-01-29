require "stone/type"
require "stone/types"
require "extensions/llvm_module"
require "stone/built_ins"


RSpec.describe "Type aliases and generic types" do

  after do
    Stone::TypeRegistry.instance.reset!
    Stone::Types.bootstrap_registry!
  end

  describe "Stone::Type::Record (generic type)" do
    it "exists as a constant" do
      expect(Stone::Type::Record).to be_a(Stone::Type)
    end

    it "is a primitive type" do
      expect(Stone::Type::Record.primitive?).to be true
    end

    it "has generic_for set to :record" do
      expect(Stone::Type::Record.generic_for).to eq(:record)
    end

    it "is registered in the type registry" do
      expect(Stone::TypeRegistry.instance.lookup("Record")).to eq(Stone::Type::Record)
    end

    it "has RTTI type_kind of KIND_RECORD" do
      expect(Stone::RTTI.type_kind(Stone::Type::Record)).to eq(Stone::RTTI::KIND_RECORD)
    end
  end

  describe "Stone::Type::Function (generic_for)" do
    it "exists as a constant" do
      expect(Stone::Type::Function).to be_a(Stone::Type)
    end

    it "has generic_for set to :function" do
      expect(Stone::Type::Function.generic_for).to eq(:function)
    end
  end

  describe "Stone::Type::Primitive" do
    it "exists as a constant" do
      expect(Stone::Type::Primitive).to be_a(Stone::Type)
    end

    it "is a union type" do
      expect(Stone::Type::Primitive.union?).to be true
    end

    it "has exactly Null, Bool, Int, and String as alternatives" do
      expect(Stone::Type::Primitive.alternatives).to contain_exactly(
        Stone::Type::Null,
        Stone::Type::Bool,
        Stone::Type::Int,
        Stone::Type::String
      )
    end

    it "has the name 'Primitive'" do
      expect(Stone::Type::Primitive.name).to eq("Primitive")
    end

    it "is registered in the type registry" do
      expect(Stone::TypeRegistry.instance.lookup("Primitive")).to eq(Stone::Type::Primitive)
    end

    it "is compatible with Int" do
      expect(Stone::Type::Primitive.compatible_with?(Stone::Type::Int)).to be true
    end

    it "is compatible with String" do
      expect(Stone::Type::Primitive.compatible_with?(Stone::Type::String)).to be true
    end

    it "is not compatible with a record type" do
      record = Stone::Type.record(name: "Point", fields: [{name: "x", type: "Int"}], llvm_type: :mock)
      expect(Stone::Type::Primitive.compatible_with?(record)).to be false
    end
  end

  describe "Stone::Type::Any" do
    it "exists as a constant" do
      expect(Stone::Type::Any).to be_a(Stone::Type)
    end

    it "is a union type" do
      expect(Stone::Type::Any.union?).to be true
    end

    it "has exactly Null, Bool, Int, String, Record, Function, and Type as alternatives" do
      expect(Stone::Type::Any.alternatives).to contain_exactly(
        Stone::Type::Null,
        Stone::Type::Bool,
        Stone::Type::Int,
        Stone::Type::String,
        Stone::Type::Record,
        Stone::Type::Function,
        Stone::Type::Type
      )
    end

    it "has the name 'Any'" do
      expect(Stone::Type::Any.name).to eq("Any")
    end

    it "is registered in the type registry" do
      expect(Stone::TypeRegistry.instance.lookup("Any")).to eq(Stone::Type::Any)
    end

    it "is compatible with Int" do
      expect(Stone::Type::Any.compatible_with?(Stone::Type::Int)).to be true
    end

    it "is compatible with a record type (via generic Record)" do
      record = Stone::Type.record(name: "Point", fields: [{name: "x", type: "Int"}], llvm_type: :mock)
      expect(Stone::Type::Any.compatible_with?(record)).to be true
    end

    it "is compatible with a function type (via generic Function)" do
      func = Stone::Type.function(param_types: [Stone::Type::Int], return_type: Stone::Type::Int)
      expect(Stone::Type::Any.compatible_with?(func)).to be true
    end
  end

  describe "equals? type signature", :llvm do
    let(:mod) { LLVM::Module.new("test") }
    let(:equals_type) { Stone::TypeRegistry.instance.lookup("equals?") }

    before do
      Stone::BuiltIns.new(mod).setup
    end

    it "is registered in the type registry" do
      expect(equals_type).not_to be_nil
    end

    it "is a function type" do
      expect(equals_type.function?).to be true
    end

    it "takes two Any parameters" do
      expect(equals_type.param_types).to eq([Stone::Type::Any, Stone::Type::Any])
    end

    it "returns Bool" do
      expect(equals_type.return_type).to eq(Stone::Type::Bool)
    end
  end

end
