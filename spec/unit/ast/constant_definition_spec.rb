require "stone/ast/constant_definition"
require "stone/ast/integer_literal"
require "stone/ast/function_call"
require "stone/ast/reference"
require "llvm/core"


RSpec.describe Stone::AST::ConstantDefinition do

  describe "#to_llir" do
    let(:mod) { LLVM::Module.new("test") }
    let(:builder) { LLVM::Builder.new }

    before do
      # Setup a basic block for the builder
      func_type = LLVM::Type.function([], LLVM::Int64)
      func = mod.functions.add("test_func", func_type)
      entry = func.basic_blocks.append("entry")
      builder.position_at_end(entry)
    end

    context "when value is a literal" do
      let(:literal) { Stone::AST::IntegerLiteral.new(42) }
      let(:const_def) { described_class.new("MY_CONST", literal) }

      it "creates a global constant with literal initializer" do
        const_def.to_llir(builder, mod)

        global = mod.globals["MY_CONST"]
        expect(global).not_to be_nil
        expect(global.global_constant?).to be true
        expect(global.initializer.to_s).to eq("i64 42")
      end

      it "does not generate a store instruction" do
        ir_before = mod.to_s
        const_def.to_llir(builder, mod)
        ir_after = mod.to_s

        # The IR should not contain a store instruction for this constant
        new_ir = ir_after.gsub(ir_before, "")
        expect(new_ir).not_to match(/store.*MY_CONST/)
      end
    end

    context "when value is a function call" do
      let(:function_call) do
        # Mock a function call AST node
        instance_double(
          Stone::AST::FunctionCall,
          to_llir: LLVM::Int64.from_i(42)
        )
      end
      let(:const_def) { described_class.new("COMPUTED", function_call) }

      it "creates a mutable global with dummy initializer" do
        const_def.to_llir(builder, mod)

        global = mod.globals["COMPUTED"]
        expect(global).not_to be_nil
        expect(global.global_constant?).to be false
        # Initializer is a dummy zero value
      end

      it "generates a store instruction" do
        const_def.to_llir(builder, mod)

        ir = mod.to_s
        expect(ir).to match(/store.*COMPUTED/)
      end
    end

    context "when value is a reference to another constant" do
      let(:reference) do
        # Mock a reference AST node that returns a load instruction
        instance_double(
          Stone::AST::Reference,
          to_llir: LLVM::Int64.from_i(1)
        )
      end
      let(:const_def) { described_class.new("COPY", reference) }

      it "creates a mutable global with runtime initialization" do
        const_def.to_llir(builder, mod)

        global = mod.globals["COPY"]
        expect(global).not_to be_nil
        expect(global.global_constant?).to be false
      end
    end
  end

end
