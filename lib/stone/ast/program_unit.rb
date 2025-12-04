require "stone/ast"
require "stone/ast/program_unit/top_function"
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
          setup_predefined_constants(mod)
          setup_builtin_functions(mod)
          generate_top_function(mod)
        end
      end

      private def setup_predefined_constants(mod)
        define_constant(mod, "ZERO", 0)
        define_constant(mod, "ONE", 1)
      end

      private def define_constant(mod, name, value)
        mod.globals.add(LLVM::Int64, name).tap do |global|
          global.initializer = LLVM::Int64.from_i(value)
          global.linkage = :internal
          global.global_constant = true
        end
      end

      private def setup_builtin_functions(mod)
        define_sum_function(mod)
        define_comparison_operators(mod)
        define_if_function(mod)
      end

      private def define_comparison_operators(mod)
        define_comparison(mod, "==", :eq)
        define_comparison(mod, "!=", :ne)
        define_comparison(mod, "≠", :ne)
        define_comparison(mod, "<", :slt)
        define_comparison(mod, "<=", :sle)
        define_comparison(mod, "≤", :sle)
        define_comparison(mod, ">", :sgt)
        define_comparison(mod, ">=", :sge)
        define_comparison(mod, "≥", :sge)
      end

      private def define_comparison(mod, name, predicate)
        mod.functions.add(name, comparison_function_type).tap { |func| build_icmp_body(func, predicate) }
      end

      private def comparison_function_type
        @comparison_function_type ||= LLVM::Type.function([LLVM::Int64.type, LLVM::Int64.type], LLVM::Int1.type)
      end

      private def build_icmp_body(func, predicate)
        func.basic_blocks.append("entry").build do |builder|
          result = builder.icmp(predicate, func.params[0], func.params[1], "cmp_result")
          builder.ret(result)
        end
      end

      private def define_sum_function(mod)
        i64 = LLVM::Int64.type
        function_type = LLVM::Type.function([i64, i64], i64)
        mod.functions.add("sum", function_type).tap { |func| build_sum_body(func, mod) }
      end

      private def build_sum_body(func, mod)
        func.basic_blocks.append("entry").build do |builder|
          intrinsic = sadd_with_overflow_intrinsic(mod)
          result = builder.call(intrinsic, func.params[0], func.params[1], "sadd_result")
          # TODO: Check for overflow (something like `builder.extract_value(result, 0) == 1`) and branch to return a Stone::Type::Error if true.
          # overflowed = builder.extract_value(result, 1)
          sum_value = builder.extract_value(result, 0, "sum")
          builder.ret(sum_value)
        end
      end

      private def define_if_function(mod)
        i1 = LLVM::Int1.type
        i64 = LLVM::Int64.type
        # Block type: () -> i64
        block_type = LLVM::Type.function([], i64)
        block_ptr = LLVM::Type.pointer(block_type)
        # if takes: (i1 condition, block* then_block, block* else_block) -> i64
        function_type = LLVM::Type.function([i1, block_ptr, block_ptr], i64)
        mod.functions.add("if", function_type).tap { |func| build_if_body(func) }
      end

      private def build_if_body(func)
        blocks = create_if_basic_blocks(func)
        build_if_entry(blocks, func.params[0])
        then_result = build_if_branch(blocks[:then_bb], blocks[:merge_bb], func.params[1], "then_result")
        else_result = build_if_branch(blocks[:else_bb], blocks[:merge_bb], func.params[2], "else_result")
        build_if_merge(blocks, then_result, else_result)
      end

      private def create_if_basic_blocks(func)
        {
          entry_bb: func.basic_blocks.append("entry"),
          then_bb: func.basic_blocks.append("then"),
          else_bb: func.basic_blocks.append("else"),
          merge_bb: func.basic_blocks.append("merge")
        }
      end

      private def build_if_entry(blocks, condition)
        blocks[:entry_bb].build { |builder| builder.cond(condition, blocks[:then_bb], blocks[:else_bb]) }
      end

      private def build_if_branch(branch_bb, merge_bb, block_ptr, result_name)
        result = nil
        branch_bb.build do |builder|
          result = builder.call2(block_func_type, block_ptr, result_name)
          builder.br(merge_bb)
        end
        result
      end

      private def build_if_merge(blocks, then_result, else_result)
        blocks[:merge_bb].build do |builder|
          phi = builder.phi(LLVM::Int64.type, {blocks[:then_bb] => then_result, blocks[:else_bb] => else_result}, "if_result")
          builder.ret(phi)
        end
      end

      private def block_func_type
        @block_func_type ||= LLVM::Type.function([], LLVM::Int64.type)
      end

      private def sadd_with_overflow_intrinsic(mod)
        intrinsic_name = "llvm.sadd.with.overflow.i64"
        return mod.functions[intrinsic_name] if mod.functions[intrinsic_name]

        i64 = LLVM::Int64.type
        i1 = LLVM::Int1.type
        result_type = LLVM::Type.struct([i64, i1], false)
        function_type = LLVM::Type.function([i64, i64], result_type)
        mod.functions.add(intrinsic_name, function_type)
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
