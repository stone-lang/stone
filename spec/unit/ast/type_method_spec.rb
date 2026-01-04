require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/boolean_literal"
require "stone/ast/string_literal"
require "stone/ast/reference"
require "stone/ast/property_access"
require "stone/ast/record_instantiation"
require "stone/ast/type_of_expression"
require "stone/ast/type_reference"
require "stone/ast/function_call"
require "stone/ast/lambda"
require "stone/ast/block"
require "stone/ast/constant_definition"
require "stone/type_context"
require "stone/types"

RSpec.describe "AST node type() method" do

  let(:context) { Stone::TypeContext.new }

  describe "IntegerLiteral#type" do
    it "returns Stone::Type::Int" do
      node = Stone::AST::IntegerLiteral.new(42)
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "works without context" do
      node = Stone::AST::IntegerLiteral.new(42)
      expect(node.type).to eq(Stone::Type::Int)
    end
  end

  describe "BooleanLiteral#type" do
    it "returns Stone::Type::Bool" do
      node = Stone::AST::BooleanLiteral.new("TRUE")
      expect(node.type(context)).to eq(Stone::Type::Bool)
    end

    it "works without context" do
      node = Stone::AST::BooleanLiteral.new("FALSE")
      expect(node.type).to eq(Stone::Type::Bool)
    end
  end

  describe "StringLiteral#type" do
    it "returns Stone::Type::String" do
      node = Stone::AST::StringLiteral.new("hello")
      expect(node.type(context)).to eq(Stone::Type::String)
    end

    it "works without context" do
      node = Stone::AST::StringLiteral.new("world")
      expect(node.type).to eq(Stone::Type::String)
    end
  end

  describe "Reference#type" do
    it "returns the bound type for known variable" do
      context.bind("x", Stone::Type::Int)
      node = Stone::AST::Reference.new("x")
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "raises TypeError for unknown variable" do
      node = Stone::AST::Reference.new("unknown")
      expect { node.type(context) }.to raise_error(Stone::TypeError, /Unknown identifier: unknown/)
    end

    it "returns nil when no context is provided" do
      node = Stone::AST::Reference.new("x")
      expect(node.type).to be_nil
    end
  end

  describe "PropertyAccess#type" do
    it "returns the property return type for Int.positive?" do
      receiver = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::PropertyAccess.new(receiver, "positive?")
      expect(node.type(context)).to eq(Stone::Type::Bool)
    end

    it "returns the property return type for Bool.not" do
      receiver = Stone::AST::BooleanLiteral.new("TRUE")
      node = Stone::AST::PropertyAccess.new(receiver, "not")
      expect(node.type(context)).to eq(Stone::Type::Bool)
    end

    it "returns the property return type for String.byte_count" do
      receiver = Stone::AST::StringLiteral.new("hello")
      node = Stone::AST::PropertyAccess.new(receiver, "byte_count")
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "raises PropertyError for unknown property" do
      receiver = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::PropertyAccess.new(receiver, "unknown")
      expect { node.type(context) }.to raise_error(Stone::PropertyError, /Property 'unknown' not found/)
    end

    it "handles chained property access" do
      inner_receiver = Stone::AST::IntegerLiteral.new(42)
      inner_access = Stone::AST::PropertyAccess.new(inner_receiver, "positive?")
      outer_access = Stone::AST::PropertyAccess.new(inner_access, "not")
      expect(outer_access.type(context)).to eq(Stone::Type::Bool)
    end
  end

  describe "TypeOfExpression#type" do
    it "returns Stone::Type::Type" do
      inner = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::TypeOfExpression.new(inner)
      expect(node.type(context)).to eq(Stone::Type::Type)
    end

    it "works without context" do
      inner = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::TypeOfExpression.new(inner)
      expect(node.type).to eq(Stone::Type::Type)
    end
  end

  describe "TypeReference#type" do
    it "returns Stone::Type::Type" do
      node = Stone::AST::TypeReference.new
      expect(node.type(context)).to eq(Stone::Type::Type)
    end

    it "works without context" do
      node = Stone::AST::TypeReference.new
      expect(node.type).to eq(Stone::Type::Type)
    end
  end

  describe "RecordInstantiation#type" do
    it "returns the record type name" do
      field_values = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::RecordInstantiation.new("Point", field_values)
      expect(node.type(context)).to eq("Point")
    end

    it "works without context" do
      field_values = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::RecordInstantiation.new("Point", field_values)
      expect(node.type).to eq("Point")
    end
  end

  describe "FunctionCall#type" do
    it "returns Stone::Type::Bool for comparison operators" do
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      %w[== != ≠ < <= ≤ > >= ≥].each do |op|
        node = Stone::AST::FunctionCall.new(op, args)
        expect(node.type(context)).to eq(Stone::Type::Bool)
      end
    end

    it "returns Stone::Type::Int for regular functions" do
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      node = Stone::AST::FunctionCall.new("add", args)
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "works without context" do
      args = [Stone::AST::IntegerLiteral.new(1)]
      node = Stone::AST::FunctionCall.new("foo", args)
      expect(node.type).to eq(Stone::Type::Int)
    end
  end

  describe "Lambda#type" do
    it "returns the type of its block" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Lambda.new(["x"], statements)
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "returns Bool when block returns Bool" do
      statements = [Stone::AST::BooleanLiteral.new("TRUE")]
      node = Stone::AST::Lambda.new([], statements)
      expect(node.type(context)).to eq(Stone::Type::Bool)
    end

    it "returns String when block returns String" do
      statements = [Stone::AST::StringLiteral.new("hello")]
      node = Stone::AST::Lambda.new([], statements)
      expect(node.type(context)).to eq(Stone::Type::String)
    end

    it "works without context" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Lambda.new([], statements)
      expect(node.type).to eq(Stone::Type::Int)
    end
  end

  describe "Block#type" do
    it "infers type from last expression" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "infers Bool type from last expression" do
      statements = [Stone::AST::BooleanLiteral.new("TRUE")]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(Stone::Type::Bool)
    end

    it "infers String type from last expression" do
      statements = [Stone::AST::StringLiteral.new("hello")]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(Stone::Type::String)
    end

    it "skips definitions when inferring type" do
      statements = [
        Stone::AST::IntegerLiteral.new(1),
        Stone::AST::ConstantDefinition.new("X", Stone::AST::IntegerLiteral.new(42))
      ]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(Stone::Type::Int)
    end

    it "returns nil for empty block" do
      node = Stone::AST::Block.new([])
      expect(node.type(context)).to be_nil
    end

    it "works without context" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Block.new(statements)
      expect(node.type).to eq(Stone::Type::Int)
    end
  end

end
