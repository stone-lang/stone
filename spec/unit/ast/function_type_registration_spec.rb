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

  describe "built-in function types" do
    it "registers sum function type" do
      ast = Stone.compile("1")
      ast.to_llir

      func_type = registry.lookup("sum")
      expect(func_type).not_to be_nil
      expect(func_type.function?).to be true
      expect(func_type.param_types).to eq([Stone::Type::Int, Stone::Type::Int])
      expect(func_type.return_type).to eq(Stone::Type::Int)
    end

    it "registers if function type" do
      ast = Stone.compile("1")
      ast.to_llir

      func_type = registry.lookup("if")
      expect(func_type).not_to be_nil
      expect(func_type.function?).to be true
      expect(func_type.return_type).to eq(Stone::Type::Int)
    end

    it "allows FunctionCall#type to return Int for sum" do
      ast = Stone.compile("sum(1, 2)")
      ast.to_llir

      func_call = ast.children.last
      expect(func_call.type).to eq(Stone::Type::Int)
    end
  end

  describe "chained expressions" do
    it "returns Bool for sum(1, 2).positive?" do
      ast = Stone.compile("sum(1, 2).positive?")
      ast.to_llir

      property_access = ast.children.last
      expect(property_access).to be_a(Stone::AST::PropertyAccess)
      expect(property_access.type).to eq(Stone::Type::Bool)
    end

    it "returns Bool for add(1, 2).positive? with user-defined function" do
      ast = Stone.compile("add := λ(a, b) { sum(a, b) }\nadd(1, 2).positive?")
      ast.to_llir

      property_access = ast.children.last
      expect(property_access).to be_a(Stone::AST::PropertyAccess)
      expect(property_access.type).to eq(Stone::Type::Bool)
    end
  end

end
