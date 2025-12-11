require "stone/ast"
require "stone/ast/program_unit/top_function"
require "stone/built_ins"
require "llvm/core"
require "llvm/execution_engine"


module Stone
  class AST
    class ProgramUnit < Stone::AST

      def initialize(children)
        super(:program_unit, children)
        @top_function = TopFunction.new(children)
        LLVM.init_jit
      end

      def to_llir
        module_ref
      end

      def eval(function_name = "__top__")
        result, result_type = run_function(global_function(function_name))
        convert_to_ruby(result, result_type)
      ensure
        jit_engine&.dispose
      end

      def type(_context = nil)
        # ProgramUnit doesn't have a meaningful type
        nil
      end

      private def run_function(func)
        result = jit_engine.run_function(func)
        result_type = result_type(func.function_type.return_type)
        [result, result_type]
      end

      private def result_type(llvm_type)
        case llvm_type.to_s
        when "i64" then resolve_i64_type
        when "i1" then :boolean
        else llvm_type
        end
      end

      private def resolve_i64_type
        return :string if last_child_is_string?
        return :boolean if last_child_is_boolean?

        :i64
      end

      private def convert_to_ruby(result, result_type)
        case result_type.to_s
        when "string"
          read_string_from_pointer(result.to_i)
        when "boolean"
          result.to_i != 0
        when "i64"
          result.to_i
        else
          fail "Don't know how to convert LLVM type to Ruby: #{result_type}"
        end
      end

      private def read_string_from_pointer(ptr_addr)
        return "" if ptr_addr.zero?

        FFI::Pointer.new(ptr_addr).read_string.force_encoding(Encoding::UTF_8)
      end

      private def jit_engine
        @jit_engine ||= LLVM::JITCompiler.new(module_ref)
      end

      private def global_function(function_name)
        module_ref.functions[function_name]
      end

      private def last_child_is_string?
        last_child = children&.last
        return false unless last_child

        last_child.is_a?(Stone::AST::StringLiteral) ||
          string_constant_reference?(last_child) ||
          string_property_access?(last_child)
      end

      private def last_child_is_boolean?
        last_child = children&.last
        return false unless last_child

        last_child.is_a?(Stone::AST::BooleanLiteral) || boolean_function_call?(last_child) || boolean_property_access?(last_child)
      end

      private def boolean_function_call?(node)
        return false unless node.is_a?(Stone::AST::FunctionCall)
        func = module_ref.functions[node.function_name]
        func&.function_type&.return_type&.to_s == "i1"
      end

      private def boolean_property_access?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)
        # Property access returns i1 if the property itself returns a boolean
        infer_property_return_type(node) == "Bool"
      end

      private def string_constant_reference?(node)
        return false unless node.is_a?(Stone::AST::Reference)
        node.type(module_ref) == "String"
      end

      private def string_property_access?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)
        return true if node.property == "as_String" # as_String always returns a string
        node.returns_string_field?(module_ref)
      end

      private def infer_receiver_type(node)
        literal_type(node) || reference_type(node) || property_access_type(node)
      end

      private def literal_type(node)
        case node
        when Stone::AST::IntegerLiteral then "Int"
        when Stone::AST::BooleanLiteral then "Bool"
        when Stone::AST::StringLiteral then "String"
        when Stone::AST::TypeOfExpression then "Type"
        when Stone::AST::TypeReference then "Type"
        end
      end

      private def reference_type(node)
        node.type(module_ref) if node.is_a?(Stone::AST::Reference)
      end

      private def property_access_type(node)
        infer_property_return_type(node) if node.is_a?(Stone::AST::PropertyAccess)
      end

      private def infer_property_return_type(property_access_node)
        receiver_type = infer_receiver_type(property_access_node.receiver)
        return nil unless receiver_type

        # Check what type this property returns
        property_return_types = {
          "Bool" => {"not" => "Bool", "as_String" => "String"},
          "Int" => {"positive?" => "Bool", "negative?" => "Bool", "zero?" => "Bool", "as_String" => "String"},
          "String" => {"byte_count" => "Int", "empty?" => "Bool", "as_String" => "String"},
          "Type" => {"as_String" => "String"}
        }

        property_return_types.dig(receiver_type, property_access_node.property)
      end

      private def module_ref
        @module_ref ||= create_module
      end

      private def create_module
        LLVM::Module.new("__program_unit__").tap do |mod|
          Stone::BuiltIns.new(mod).setup
          generate_top_function(mod)
        end
      end

      # Generate IR for all code that's directly in the module.
      # TODO: Maybe pass in `ARGV` and `ENV`.
      # ... for `ARGV`, we'll probably need to implement `main(argc, argv, envp)`.
      # ... for `ENV`, we can probably call `getenv`, maybe `environ`.
      # Look into run_function_as_main(engine, fn, argc, argv, envp)
      private def generate_top_function(mod)
        @top_function.generate(mod)
      end
    end
  end
end
