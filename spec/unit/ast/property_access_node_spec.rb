require "stone"
require "stone/scope"

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def setup_prelude_properties(mod)
  prelude_code = <<~STONE
    Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
    Int@positive? := λ(this) { this > 0 }
    Int@negative? := λ(this) { this < 0 }
    Int@zero? := λ(this) { this == 0 }
  STONE
  parse_tree = Stone::Grammar.parse(prelude_code)
  transformer = Stone::Transform.new
  ast = transformer.transform(parse_tree)

  builder_temp = LLVM::Builder.new
  func_temp = mod.functions.add("__prelude_setup__", LLVM::Type.function([], LLVM::Int64.type))
  block_temp = func_temp.basic_blocks.append("entry")
  builder_temp.position_at_end(block_temp)

  ast.children.each { |child| child.to_llir(builder_temp, mod) if child.respond_to?(:to_llir) }
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

RSpec.shared_context "with LLVM builder and prelude" do
  let(:mod) { LLVM::Module.new("test") }
  let(:func) { mod.functions.add("test_func", LLVM::Type.function([], LLVM::Int64.type)) }
  let(:block) { func.basic_blocks.append("entry") }
  let(:builder) { LLVM::Builder.new }

  before do
    builder.position_at_end(block)
    Stone::BuiltIns.new(mod).setup
    setup_prelude_properties(mod)
  end
end

RSpec.describe Stone::AST::PropertyAccess do

  describe "#initialize" do
    it "stores receiver and property name" do
      receiver = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::PropertyAccess.new(receiver, "positive?")

      expect(node.receiver).to eq(receiver)
      expect(node.property).to eq("positive?")
    end
  end

  describe "#to_llir" do
    include_context "with LLVM builder and prelude"

    describe "Int properties" do
      it "generates LLVM IR for Int.positive?" do
        receiver = Stone::AST::IntegerLiteral.new(42)
        node = Stone::AST::PropertyAccess.new(receiver, "positive?")

        result = node.to_llir(builder, mod)

        expect(result).to be_a(LLVM::Value)
        expect(result.type.to_s).to eq("i1")
      end

      it "generates LLVM IR for Int.negative?" do
        receiver = Stone::AST::IntegerLiteral.new(-5)
        node = Stone::AST::PropertyAccess.new(receiver, "negative?")

        result = node.to_llir(builder, mod)

        expect(result).to be_a(LLVM::Value)
        expect(result.type.to_s).to eq("i1")
      end

      it "generates LLVM IR for Int.zero?" do
        receiver = Stone::AST::IntegerLiteral.new(0)
        node = Stone::AST::PropertyAccess.new(receiver, "zero?")

        result = node.to_llir(builder, mod)

        expect(result).to be_a(LLVM::Value)
        expect(result.type.to_s).to eq("i1")
      end
    end

    describe "Bool properties" do
      it "generates LLVM IR for Bool.not" do
        receiver = Stone::AST::BooleanLiteral.new("TRUE")
        node = Stone::AST::PropertyAccess.new(receiver, "not")

        result = node.to_llir(builder, mod)

        expect(result).to be_a(LLVM::Value)
        expect(result.type.to_s).to eq("i64")
      end
    end

    describe "String properties" do
      it "generates LLVM IR for String.byte_count" do
        receiver = Stone::AST::StringLiteral.new("hello")
        node = Stone::AST::PropertyAccess.new(receiver, "byte_count")

        result = node.to_llir(builder, mod)

        expect(result).to be_a(LLVM::Value)
        expect(result.type).to eq(LLVM::Int64.type)
      end
    end

    describe "error handling" do
      it "raises error for unknown property" do
        receiver = Stone::AST::IntegerLiteral.new(42)
        node = Stone::AST::PropertyAccess.new(receiver, "unknown")

        expect { node.to_llir(builder, mod) }.to raise_error(/Property.*not found/)
      end

      it "raises error for property on unsupported type" do
        receiver = Stone::AST::IntegerLiteral.new(42)
        node = Stone::AST::PropertyAccess.new(receiver, "byte_count") # String property on Int

        expect { node.to_llir(builder, mod) }.to raise_error(/Property.*not found/)
      end
    end
  end

  describe "chained property access" do
    include_context "with LLVM builder and prelude"

    it "handles chained properties correctly" do
      # TRUE.not.not
      inner_receiver = Stone::AST::BooleanLiteral.new("TRUE")
      inner = Stone::AST::PropertyAccess.new(inner_receiver, "not")
      outer = Stone::AST::PropertyAccess.new(inner, "not")

      result = outer.to_llir(builder, mod)

      expect(result).to be_a(LLVM::Value)
      expect(result.type.to_s).to eq("i64")
    end
  end

end
