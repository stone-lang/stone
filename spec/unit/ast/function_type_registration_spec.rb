require "stone"
require "stone/types"


RSpec.describe "Function type registration" do

  let(:registry) { Stone::TypeRegistry.instance }

  after do
    registry.reset!
    Stone::Types.bootstrap_registry!
  end

  describe "lambda assigned to constant" do
    it "registers function type under the constant name" do
      ast = Stone.compile("add := λ(a, b) { sum(a, b) }")
      ast.to_llir # Triggers registration

      func_type = registry.lookup("add")
      expect(func_type).not_to be_nil
      expect(func_type.function?).to be true
    end

    it "registers correct parameter types" do
      ast = Stone.compile("add := λ(a, b) { sum(a, b) }")
      ast.to_llir

      func_type = registry.lookup("add")
      expect(func_type.param_types).to eq([Stone::Type::Int, Stone::Type::Int])
    end

    it "registers correct return type for Int-returning function" do
      ast = Stone.compile("add := λ(a, b) { sum(a, b) }")
      ast.to_llir

      func_type = registry.lookup("add")
      expect(func_type.return_type).to eq(Stone::Type::Int)
    end

    it "registers correct return type for Bool-returning function" do
      ast = Stone.compile("is_positive := λ(n) { >(n, 0) }")
      ast.to_llir

      func_type = registry.lookup("is_positive")
      expect(func_type.return_type).to eq(Stone::Type::Bool)
    end

    it "registers correct return type for String-returning function" do
      ast = Stone.compile('greeting := λ(x) { "hello" }')
      ast.to_llir

      func_type = registry.lookup("greeting")
      expect(func_type.return_type).to eq(Stone::Type::String)
    end
  end

  describe "FunctionCall#type uses registered function type" do
    it "returns return type for user-defined function call" do
      ast = Stone.compile("add := λ(a, b) { sum(a, b) }\nadd(1, 2)")
      ast.to_llir

      # Verify the function type is registered
      func_type = registry.lookup("add")
      expect(func_type.return_type).to eq(Stone::Type::Int)

      # Verify FunctionCall#type returns the correct return type
      function_call = ast.children.last
      expect(function_call).to be_a(Stone::AST::FunctionCall)
      expect(function_call.type).to eq(Stone::Type::Int)
    end
  end

end
