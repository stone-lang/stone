require "stone"
require "stone/scope"

RSpec.describe "Type Declaration Tracking" do

  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "transformation" do
    it "transforms type declaration to TypeDeclaration AST node" do
      code = "x :: Int"
      ast = Stone.compile(code)
      statements = ast.children
      type_decl = statements.find { |s| s.is_a?(Stone::AST::TypeDeclaration) }
      expect(type_decl).not_to be_nil
      expect(type_decl.identifier).to eq("x")
      expect(type_decl.type_annotation).to be_a(Stone::AST::TypeAnnotation)
      expect(type_decl.type_annotation.type_name).to eq("Int")
    end

    it "preserves source location" do
      code = "answer :: Int"
      ast = Stone.compile(code)
      statements = ast.children
      type_decl = statements.find { |s| s.is_a?(Stone::AST::TypeDeclaration) }
      expect(type_decl.location).not_to be_nil
      expect(type_decl.location[:line]).to be_a(Integer)
      expect(type_decl.location[:column]).to be_a(Integer)
    end
  end

  describe "registration in scope" do
    it "registers type declaration in current scope" do
      code = <<~STONE
        x :: Int
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "stores the declared type for lookup" do
      code = <<~STONE
        answer :: Int
        answer := 42
        answer
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(result).to eq(42)
      expect(scope.declared_type("answer")).to be_a(Stone::Type)
      expect(scope.declared_type("answer").to_s).to eq("Int")
    end

    it "handles multiple type declarations" do
      code = <<~STONE
        x :: Int
        y :: Bool
        x := 42
        y := TRUE
        x
      STONE
      _result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("x").to_s).to eq("Int")
      expect(scope.declared_type("y").to_s).to eq("Bool")
    end

    it "retains source location in scope" do
      code = <<~STONE
        answer :: Int
        answer := 42
        answer
      STONE
      _result, scope = Stone.eval_with_scope(code)
      location = scope.type_declaration_location("answer")
      expect(location).not_to be_nil
      expect(location[:line]).to be_a(Integer)
    end
  end

  describe "processing order" do
    it "processes type declarations before definitions" do
      code = <<~STONE
        x := 42
        x :: Int
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(result).to eq(42)
      # Type declaration should be available even though it appears after definition
      expect(scope.declared_type("x").to_s).to eq("Int")
    end
  end

  describe "with record types" do
    it "tracks record type declarations" do
      code = <<~STONE
        Point :: Type
        Point := Record(x :: Int, y :: Int)
        Point
      STONE
      _result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("Point").to_s).to eq("Type")
    end

    it "does not register record field declarations in scope" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point
      STONE
      _result, scope = Stone.eval_with_scope(code)
      # x and y are field declarations, not statement-level type declarations
      expect(scope.declared_type("x")).to be_nil
      expect(scope.declared_type("y")).to be_nil
    end
  end

  describe "without declaration" do
    it "returns nil for undeclared identifiers" do
      code = <<~STONE
        x := 42
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(result).to eq(42)
      expect(scope.declared_type("x")).to be_nil
    end
  end

  describe "in nested blocks" do
    it "does not leak type declarations to parent scope" do
      code = <<~STONE
        func := λ() { inner :: Int; inner := 100; inner }
        result := func()
        result
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(result).to eq(100)
      expect(scope.declared_type("inner")).to be_nil
    end
  end

end
