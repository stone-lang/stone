require "stone/ast"
require "llvm/core"
require "llvm/execution_engine"


module Stone
  class AST
    class ProgramUnit < Stone::AST

      def initialize(name, children)
        super
        LLVM.init_jit
      end

      def to_llir
        module_ref
      end

      def eval(function_name = "__top__")
        fn = global_function(function_name)
        result = jit_engine.run_function(fn)
        convert_llvm_result_to_ruby(result, fn.return_type)
      ensure
        jit_engine&.dispose
      end

      private def jit_engine
        @jit_engine ||= LLVM::JITCompiler.new(module_ref)
      end

      private def global_function(function_name)
        module_ref.functions[function_name]
      end

      private def convert_llvm_result_to_ruby(result, result_type)
        case result_type.to_s
        when "i64"
          # Convert LLVM GenericValue to signed Ruby integer
          result.to_i
        else
          fail "Don't know how to convert this LLVM type yet: #{result_type}."
        end
      end

      private def module_ref
        @module_ref ||= create_module
      end

      private def create_module
        LLVM::Module.new("__program_unit__").tap do |mod|
          generate_top_function(mod)
        end
      end

      private def top_type
        @top_type ||= LLVM::Type.function([], LLVM::Type.i(64), varargs: false)
      end

      private def generate_top_function(mod = module_ref)
        # TODO: Maybe pass in `ARGV` and `ENV`.
        # ... for `ARGV`, we'll probably need to implement `main(argc, argv, envp)`.
        # ... for `ENV`, we can probably call `getenv`, maybe `environ`.
        # Look into run_function_as_main(engine, fn, argc, argv, envp)

        # Generate IR for all code that's directly in the module.
        mod.functions.add("__top__", top_type) do |func|
          entry = func.basic_blocks.append("entry")
          entry.build do |bb|
            ch = children&.map { |child|
              child.to_llir(bb)
            }
            if ch.nil? || ch.empty?
              bb.ret(LLVM::Type.void)
            else
              bb.ret(ch.last)
            end
          end
        end
      end
    end
  end
end
