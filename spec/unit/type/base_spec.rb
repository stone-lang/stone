require "stone/types"

RSpec.describe "Stone::Type built-in types" do

  describe "#name" do
    it "returns 'Int' for Int type" do
      expect(Stone::Type::Int.name).to eq("Int")
    end

    it "returns 'Bool' for Bool type" do
      expect(Stone::Type::Bool.name).to eq("Bool")
    end

    it "returns 'String' for String type" do
      expect(Stone::Type::String.name).to eq("String")
    end
  end

  describe "#llvm_type" do
    it "returns LLVM::Int64 for Int type" do
      expect(Stone::Type::Int.llvm_type).to eq(LLVM::Int64.type)
    end

    it "returns LLVM::Int1 for Bool type" do
      expect(Stone::Type::Bool.llvm_type).to eq(LLVM::Int1.type)
    end

    it "returns LLVM::Type.pointer for String type" do
      expect(Stone::Type::String.llvm_type).to eq(LLVM::Type.pointer)
    end
  end

  describe "#property_return_type" do
    context "with Int type" do
      it "returns Bool for positive?" do
        expect(Stone::Type::Int.property_return_type("positive?")).to eq(Stone::Type::Bool)
      end

      it "returns Bool for negative?" do
        expect(Stone::Type::Int.property_return_type("negative?")).to eq(Stone::Type::Bool)
      end

      it "returns Bool for zero?" do
        expect(Stone::Type::Int.property_return_type("zero?")).to eq(Stone::Type::Bool)
      end

      it "returns String for as_String" do
        expect(Stone::Type::Int.property_return_type("as_String")).to eq(Stone::Type::String)
      end

      it "returns nil for unknown property" do
        expect(Stone::Type::Int.property_return_type("unknown")).to be_nil
      end
    end

    context "with Bool type" do
      it "returns Bool for not" do
        expect(Stone::Type::Bool.property_return_type("not")).to eq(Stone::Type::Bool)
      end

      it "returns String for as_String" do
        expect(Stone::Type::Bool.property_return_type("as_String")).to eq(Stone::Type::String)
      end

      it "returns nil for unknown property" do
        expect(Stone::Type::Bool.property_return_type("unknown")).to be_nil
      end
    end

    context "with String type" do
      it "returns Int for byte_count" do
        expect(Stone::Type::String.property_return_type("byte_count")).to eq(Stone::Type::Int)
      end

      it "returns Bool for empty?" do
        expect(Stone::Type::String.property_return_type("empty?")).to eq(Stone::Type::Bool)
      end

      it "returns String for as_String" do
        expect(Stone::Type::String.property_return_type("as_String")).to eq(Stone::Type::String)
      end

      it "returns nil for unknown property" do
        expect(Stone::Type::String.property_return_type("unknown")).to be_nil
      end
    end
  end

  describe "#as_String" do
    it "returns the type name for Int" do
      expect(Stone::Type::Int.as_String).to eq("Int")
    end

    it "returns the type name for Bool" do
      expect(Stone::Type::Bool.as_String).to eq("Bool")
    end

    it "returns the type name for String" do
      expect(Stone::Type::String.as_String).to eq("String")
    end
  end

end
