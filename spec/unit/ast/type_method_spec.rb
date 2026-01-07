require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/boolean_literal"
require "stone/ast/string_literal"
require "stone/ast/reference"
require "stone/ast/property_access"
require "stone/ast/record_instantiation"
require "stone/ast/record_definition"
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
  let(:registry) { Stone::TypeRegistry.instance }

  after do
    registry.reset!
    Stone::Types.bootstrap_registry!
  end

  describe "IntegerLiteral#type" do
    it "returns Int type instance" do
      node = Stone::AST::IntegerLiteral.new(42)
      expect(node.type(context)).to eq(registry.int)
    end

    it "works without context" do
      node = Stone::AST::IntegerLiteral.new(42)
      expect(node.type).to eq(registry.int)
    end
  end

  describe "BooleanLiteral#type" do
    it "returns Bool type instance" do
      node = Stone::AST::BooleanLiteral.new("TRUE")
      expect(node.type(context)).to eq(registry.bool)
    end

    it "works without context" do
      node = Stone::AST::BooleanLiteral.new("FALSE")
      expect(node.type).to eq(registry.bool)
    end
  end

  describe "StringLiteral#type" do
    it "returns String type instance" do
      node = Stone::AST::StringLiteral.new("hello")
      expect(node.type(context)).to eq(registry.string)
    end

    it "works without context" do
      node = Stone::AST::StringLiteral.new("world")
      expect(node.type).to eq(registry.string)
    end
  end

  describe "Reference#type" do
    it "returns the bound type for known variable" do
      context.bind("x", registry.int)
      node = Stone::AST::Reference.new("x")
      expect(node.type(context)).to eq(registry.int)
    end

    it "raises TypeError for unknown variable" do
      node = Stone::AST::Reference.new("unknown")
      expect { node.type(context) }.to raise_error(Stone::TypeError, /Unknown identifier: unknown/)
    end

    it "returns nil when no context is provided" do
      node = Stone::AST::Reference.new("x")
      expect(node.type).to be_nil
    end

    # rubocop:disable RSpec/VerifiedDoubles -- Stone extends LLVM classes with custom methods
    context "with LLVM module context" do
      let(:llvm_module) do
        double("LLVM::Module",
               lambda_param_storage: nil,
               string_constant?: false,
               record_instance?: false,
               globals: {})
      end

      it "returns Stone::Type::String for string constants" do
        allow(llvm_module).to receive(:string_constant?).with("greeting").and_return(true)
        node = Stone::AST::Reference.new("greeting")
        expect(node.type(llvm_module)).to eq(Stone::Type::String)
      end

      it "returns Stone::Type from registry for record instances" do
        point_type = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
        registry.register(point_type)
        allow(llvm_module).to receive(:record_instance?).with("p").and_return(true)
        allow(llvm_module).to receive(:record_instance_type).with("p").and_return("Point")
        node = Stone::AST::Reference.new("p")
        expect(node.type(llvm_module)).to eq(point_type)
      end

      it "returns Stone::Type::Int for i64 globals" do
        global = double("LLVM::GlobalVariable")
        initializer = double("LLVM::Value")
        llvm_type = double("LLVM::Type", kind: :integer, width: 64)
        allow(global).to receive(:initializer).and_return(initializer)
        allow(initializer).to receive(:type).and_return(llvm_type)
        allow(llvm_module).to receive(:globals).and_return({"count" => global})
        node = Stone::AST::Reference.new("count")
        expect(node.type(llvm_module)).to eq(Stone::Type::Int)
      end

      it "returns Stone::Type::Bool for i1 globals" do
        global = double("LLVM::GlobalVariable")
        initializer = double("LLVM::Value")
        llvm_type = double("LLVM::Type", kind: :integer, width: 1)
        allow(global).to receive(:initializer).and_return(initializer)
        allow(initializer).to receive(:type).and_return(llvm_type)
        allow(llvm_module).to receive(:globals).and_return({"flag" => global})
        node = Stone::AST::Reference.new("flag")
        expect(node.type(llvm_module)).to eq(Stone::Type::Bool)
      end

      it "returns Stone::Type::String for non-null pointer globals" do
        global = double("LLVM::GlobalVariable")
        initializer = double("LLVM::Value")
        llvm_type = double("LLVM::Type", kind: :pointer)
        allow(global).to receive(:initializer).and_return(initializer)
        allow(initializer).to receive_messages(type: llvm_type, null?: false)
        allow(llvm_module).to receive(:globals).and_return({"message" => global})
        node = Stone::AST::Reference.new("message")
        expect(node.type(llvm_module)).to eq(Stone::Type::String)
      end

      it "returns Stone::Type::Null for null pointer globals" do
        global = double("LLVM::GlobalVariable")
        initializer = double("LLVM::Value")
        llvm_type = double("LLVM::Type", kind: :pointer)
        allow(global).to receive(:initializer).and_return(initializer)
        allow(initializer).to receive_messages(type: llvm_type, null?: true)
        allow(llvm_module).to receive(:globals).and_return({"nothing" => global})
        node = Stone::AST::Reference.new("nothing")
        expect(node.type(llvm_module)).to eq(Stone::Type::Null)
      end

      it "returns Stone::Type::Int for lambda parameters" do
        alloca = double("LLVM::Instruction")
        llvm_type = double("LLVM::Type", kind: :integer, width: 64)
        allow(alloca).to receive(:allocated_type).and_return(llvm_type)
        allow(llvm_module).to receive(:lambda_param_storage).and_return({"x" => alloca})
        node = Stone::AST::Reference.new("x")
        expect(node.type(llvm_module)).to eq(Stone::Type::Int)
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end

  describe "PropertyAccess#type" do
    it "returns the property return type for Int.positive?" do
      receiver = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::PropertyAccess.new(receiver, "positive?")
      expect(node.type(context)).to eq(registry.bool)
    end

    it "returns the property return type for Bool.not" do
      receiver = Stone::AST::BooleanLiteral.new("TRUE")
      node = Stone::AST::PropertyAccess.new(receiver, "not")
      expect(node.type(context)).to eq(registry.bool)
    end

    it "returns the property return type for String.byte_count" do
      receiver = Stone::AST::StringLiteral.new("hello")
      node = Stone::AST::PropertyAccess.new(receiver, "byte_count")
      expect(node.type(context)).to eq(registry.int)
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
      expect(outer_access.type(context)).to eq(registry.bool)
    end

    it "works without context for literals" do
      receiver = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::PropertyAccess.new(receiver, "positive?")
      expect(node.type).to eq(registry.bool)
    end

    it "handles triple-chained property access" do
      inner = Stone::AST::IntegerLiteral.new(42)
      first = Stone::AST::PropertyAccess.new(inner, "positive?")
      second = Stone::AST::PropertyAccess.new(first, "not")
      third = Stone::AST::PropertyAccess.new(second, "not")
      expect(third.type(context)).to eq(registry.bool)
    end

    it "handles function call result with property access" do
      # sum(1, 2).positive? should return Bool
      # First, register sum's type
      sum_type = Stone::Type.function(param_types: [registry.int, registry.int], return_type: registry.int)
      registry.register_as("sum", sum_type)

      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      func_call = Stone::AST::FunctionCall.new("sum", args)
      property_access = Stone::AST::PropertyAccess.new(func_call, "positive?")

      expect(property_access.type(context)).to eq(registry.bool)
    end

    it "returns field type for record field access" do
      # Register a Point record type with x: Int, y: Int
      fields = [{name: "x", type: "Int"}, {name: "y", type: "Int"}]
      point_type = Stone::Type.record(name: "Point", fields:, llvm_type: :mock)
      registry.register(point_type)

      # Create a RecordInstantiation as the receiver
      field_values = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      receiver = Stone::AST::RecordInstantiation.new("Point", field_values)

      # Access the x field
      node = Stone::AST::PropertyAccess.new(receiver, "x")
      expect(node.type(context)).to eq(registry.int)
    end

    it "returns String type for String field on record" do
      fields = [{name: "name", type: "String"}, {name: "age", type: "Int"}]
      person_type = Stone::Type.record(name: "Person", fields:, llvm_type: :mock)
      registry.register(person_type)

      field_values = [Stone::AST::StringLiteral.new("Alice"), Stone::AST::IntegerLiteral.new(30)]
      receiver = Stone::AST::RecordInstantiation.new("Person", field_values)

      node = Stone::AST::PropertyAccess.new(receiver, "name")
      expect(node.type(context)).to eq(registry.string)
    end
  end

  describe "TypeOfExpression#type" do
    it "returns Type type instance" do
      inner = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::TypeOfExpression.new(inner)
      expect(node.type(context)).to eq(registry.type)
    end

    it "works without context" do
      inner = Stone::AST::IntegerLiteral.new(42)
      node = Stone::AST::TypeOfExpression.new(inner)
      expect(node.type).to eq(registry.type)
    end
  end

  describe "TypeReference#type" do
    it "returns Type type instance" do
      node = Stone::AST::TypeReference.new
      expect(node.type(context)).to eq(registry.type)
    end

    it "works without context" do
      node = Stone::AST::TypeReference.new
      expect(node.type).to eq(registry.type)
    end
  end

  describe "RecordInstantiation#type" do
    it "returns the record type from registry when registered" do
      point_type = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(point_type)
      field_values = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::RecordInstantiation.new("Point", field_values)
      expect(node.type(context)).to eq(point_type)
    end

    it "returns nil when type not in registry" do
      field_values = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::RecordInstantiation.new("UnknownRecord", field_values)
      expect(node.type).to be_nil
    end
  end

  describe "RecordDefinition#type" do
    it "returns nil when assigned_name is not set" do
      fields = [{name: "x", type: "Int"}]
      node = Stone::AST::RecordDefinition.new(fields)
      expect(node.type).to be_nil
    end

    it "returns constructor function type when assigned_name is set and type is registered" do
      fields = [{name: "x", type: "Int"}, {name: "y", type: "Int"}]
      point_type = Stone::Type.record(name: "Point", fields:, llvm_type: :mock)
      registry.register(point_type)

      node = Stone::AST::RecordDefinition.new(fields)
      node.assigned_name = "Point"
      func_type = node.type

      expect(func_type.function?).to be true
      expect(func_type.param_types).to eq([Stone::Type::Int, Stone::Type::Int])
      expect(func_type.return_type).to eq(point_type)
    end

    it "returns nil when assigned_name is set but type is not registered" do
      fields = [{name: "x", type: "Int"}]
      node = Stone::AST::RecordDefinition.new(fields)
      node.assigned_name = "UnregisteredType"
      expect(node.type).to be_nil
    end
  end

  describe "FunctionCall#type" do
    it "returns Bool type for comparison operators" do
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      %w[== != ≠ < <= ≤ > >= ≥].each do |op|
        node = Stone::AST::FunctionCall.new(op, args)
        expect(node.type(context)).to eq(registry.bool)
      end
    end

    it "returns nil for unknown functions" do
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      node = Stone::AST::FunctionCall.new("add", args)
      expect(node.type(context)).to be_nil
    end

    it "returns record type from registry for record constructors" do
      point_type = Stone::Type.record(name: "Point", fields: [], llvm_type: :mock)
      registry.register(point_type)
      record_context = instance_double(Stone::TypeContext, record_type?: true)
      allow(record_context).to receive(:record_type?).with("Point").and_return(true)
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      node = Stone::AST::FunctionCall.new("Point", args)
      expect(node.type(record_context)).to eq(point_type)
    end

    it "returns nil without context" do
      args = [Stone::AST::IntegerLiteral.new(1)]
      node = Stone::AST::FunctionCall.new("foo", args)
      expect(node.type).to be_nil
    end

    it "returns return type for registered function" do
      func_type = Stone::Type.function(param_types: [registry.int, registry.int], return_type: registry.int)
      registry.register_as("add", func_type)
      args = [Stone::AST::IntegerLiteral.new(1), Stone::AST::IntegerLiteral.new(2)]
      node = Stone::AST::FunctionCall.new("add", args)
      expect(node.type(context)).to eq(registry.int)
    end

    it "returns Bool return type for registered predicate function" do
      func_type = Stone::Type.function(param_types: [registry.int], return_type: registry.bool)
      registry.register_as("even?", func_type)
      args = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::FunctionCall.new("even?", args)
      expect(node.type(context)).to eq(registry.bool)
    end
  end

  describe "Lambda#type" do
    it "returns function type with inferred return type" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Lambda.new(["x"], statements)
      func_type = node.type(context)

      expect(func_type.function?).to be true
      expect(func_type.return_type).to eq(registry.int)
      expect(func_type.param_types).to eq([registry.int])
    end

    it "returns function type with Bool return" do
      statements = [Stone::AST::BooleanLiteral.new("TRUE")]
      node = Stone::AST::Lambda.new([], statements)
      func_type = node.type(context)

      expect(func_type.function?).to be true
      expect(func_type.return_type).to eq(registry.bool)
      expect(func_type.param_types).to eq([])
    end

    it "returns function type with String return" do
      statements = [Stone::AST::StringLiteral.new("hello")]
      node = Stone::AST::Lambda.new(["s"], statements)
      func_type = node.type(context)

      expect(func_type.function?).to be true
      expect(func_type.return_type).to eq(registry.string)
    end

    it "returns function type with multiple parameters" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Lambda.new(%w[a b c], statements)
      func_type = node.type(context)

      expect(func_type.function?).to be true
      expect(func_type.param_types.size).to eq(3)
      expect(func_type.name).to eq("(Int, Int, Int) -> Int")
    end

    it "works without context" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Lambda.new([], statements)
      func_type = node.type

      expect(func_type.function?).to be true
      expect(func_type.return_type).to eq(registry.int)
    end
  end

  describe "Block#type" do
    it "infers type from last expression" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(registry.int)
    end

    it "infers Bool type from last expression" do
      statements = [Stone::AST::BooleanLiteral.new("TRUE")]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(registry.bool)
    end

    it "infers String type from last expression" do
      statements = [Stone::AST::StringLiteral.new("hello")]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(registry.string)
    end

    it "skips definitions when inferring type" do
      statements = [
        Stone::AST::IntegerLiteral.new(1),
        Stone::AST::ConstantDefinition.new("X", Stone::AST::IntegerLiteral.new(42))
      ]
      node = Stone::AST::Block.new(statements)
      expect(node.type(context)).to eq(registry.int)
    end

    it "returns nil for empty block" do
      node = Stone::AST::Block.new([])
      expect(node.type(context)).to be_nil
    end

    it "works without context" do
      statements = [Stone::AST::IntegerLiteral.new(42)]
      node = Stone::AST::Block.new(statements)
      expect(node.type).to eq(registry.int)
    end
  end

end
