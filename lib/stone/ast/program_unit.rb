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

      private def run_function(func)
        if @top_function.returns_string?
          out_ptr = FFI::MemoryPointer.new(:int64)
          out_len = FFI::MemoryPointer.new(:int64)
          jit_engine.run_function(func, LLVM::GenericValue.from_ptr(out_ptr), LLVM::GenericValue.from_ptr(out_len))
          [[out_ptr, out_len], :string]
        else
          [jit_engine.run_function(func), func.function_type.return_type]
        end
      end

      private def convert_to_ruby(result, result_type)
        case result_type.to_s
        when "string"
          read_string_result(*result)
        when "i64"
          last_child_is_boolean? ? (result.to_i != 0) : result.to_i
        when "i1"
          result.to_i != 0
        else
          fail "Don't know how to convert LLVM type to Ruby: #{result_type}"
        end
      end

      private def read_string_result(out_ptr, out_len)
        ptr_addr = out_ptr.read_int64
        length = out_len.read_int64
        return "" if length.zero? || ptr_addr.zero?

        FFI::Pointer.new(ptr_addr).read_bytes(length).force_encoding(Encoding::UTF_8)
      end

      private def jit_engine
        @jit_engine ||= LLVM::JITCompiler.new(module_ref)
      end

      private def global_function(function_name)
        module_ref.functions[function_name]
      end

      private def last_child_is_boolean?
        last_child = children&.last
        last_child && last_child.is_a?(Stone::AST::BooleanLiteral) || boolean_function_call?(last_child)
      end

      private def boolean_function_call?(node)
        return false unless node.is_a?(Stone::AST::FunctionCall)
        func = module_ref.functions[node.function_name]
        func&.function_type&.return_type&.to_s == "i1"
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
