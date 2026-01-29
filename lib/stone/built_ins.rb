require "llvm/core"
require "stone/types"
require "stone/rtti"


module Stone
  # Handles registration of built-in constants (including functions and operators).
  class BuiltIns

    def initialize(mod)
      @mod = mod
    end

    def setup
      setup_rtti
      define_predefined_constants
      define_builtin_functions
      register_builtin_function_types
    end

    private def setup_rtti
      Stone::RTTI.new(@mod).setup
    end

    private def define_predefined_constants
      define_constant("ZERO", 0)
      define_constant("ONE", 1)
    end

    private def define_builtin_functions
      define_if_function
      define_sum_function
      define_comparison_operators
      define_equality_operators
      define_boolean_operators
    end

    private def define_constant(name, value)
      @mod.globals.add(LLVM::Int64, name).tap do |global|
        global.initializer = LLVM::Int64.from_i(value)
        global.linkage = :internal
        global.global_constant = true
      end
    end

    private def define_comparison_operators
      define_comparison("<", :slt)
      define_comparison("<=", :sle)
      define_comparison("≤", :sle)
      define_comparison(">", :sgt)
      define_comparison(">=", :sge)
      define_comparison("≥", :sge)
    end

    private def define_equality_operators
      equals_fn = define_equals_function
      @mod.register_function_alias("==", equals_fn)
      not_equals_fn = define_not_equals_function(equals_fn)
      @mod.register_function_alias("≠", not_equals_fn)
    end

    private def define_equals_function
      @mod.functions.add("equals?", tagged_equals_fn_type).tap { |func| build_equals_body(func) }
    end

    private def define_not_equals_function(equals_fn)
      @mod.functions.add("!=", tagged_equals_fn_type).tap { |func| build_not_equals_body(func, equals_fn) }
    end

    private def tagged_equals_fn_type
      Stone::RTTI.tagged_equals_fn_type
    end

    private def build_equals_body(func)
      blocks = create_equals_basic_blocks(func)
      build_equals_entry(blocks, func)
      build_equals_same_type(blocks, func)
      build_equals_different_type(blocks[:different_type])
    end

    private def create_equals_basic_blocks(func)
      {
        entry: func.basic_blocks.append("entry"),
        same_type: func.basic_blocks.append("same_type"),
        call_equals: func.basic_blocks.append("call_equals"),
        different_type: func.basic_blocks.append("different_type")
      }
    end

    private def build_equals_entry(blocks, func)
      blocks[:entry].build do |b|
        types_equal = b.icmp(:eq, func.params[0], func.params[2], "types_equal")
        b.cond(types_equal, blocks[:same_type], blocks[:different_type])
      end
    end

    private def build_equals_same_type(blocks, func)
      build_equals_null_check(blocks, func)
      build_equals_dispatch(blocks[:call_equals], func)
    end

    private def build_equals_null_check(blocks, func)
      blocks[:same_type].build do |b|
        fn_ptr = Stone::RTTI.load_equals_fn(b, func.params[0])
        fn_is_null = b.icmp(:eq, fn_ptr, LLVM::Type.ptr.null, "fn_is_null")
        b.cond(fn_is_null, blocks[:different_type], blocks[:call_equals])
      end
    end

    private def build_equals_dispatch(block, func)
      block.build do |b|
        fn_ptr = Stone::RTTI.load_equals_fn(b, func.params[0])
        result = b.call2(Stone::RTTI.equals_fn_type, fn_ptr, func.params[1], func.params[3], "eq_result")
        b.ret(result)
      end
    end

    private def build_equals_different_type(block)
      block.build { |b| b.ret(LLVM::FALSE) }
    end

    private def build_not_equals_body(func, equals_fn)
      func.basic_blocks.append("entry").build do |b|
        eq_result = b.call(equals_fn, func.params[0], func.params[1], func.params[2], func.params[3], "eq_result")
        b.ret(b.not(eq_result, "neq_result"))
      end
    end

    private def define_comparison(name, predicate)
      # Define binary comparison function
      # <(a, b) checks a < b
      # Chained comparisons like <(a, b, c) are handled inline in FunctionCall#to_llir
      @mod.functions.add(name, comparison_function_type).tap { |func| build_icmp_body(func, predicate) }
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

    private def define_boolean_operators
      define_boolean_binary("and", :and)
      define_boolean_binary("or", :or)
      define_boolean_binary("xor", :xor)
      define_boolean_unary("not", :xor)

      define_boolean_binary("∧", :and)
      define_boolean_binary("∨", :or)
      define_boolean_binary("⊻", :xor)
      define_boolean_unary("¬", :xor)
    end

    private def define_boolean_binary(name, instruction)
      @mod.functions.add(name, boolean_binary_function_type).tap do |func|
        build_boolean_binary_body(func, instruction)
      end
    end

    private def define_boolean_unary(name, instruction)
      @mod.functions.add(name, boolean_unary_function_type).tap do |func|
        build_boolean_unary_body(func, instruction)
      end
    end

    private def boolean_binary_function_type
      @boolean_binary_function_type ||= LLVM::Type.function([LLVM::Int1.type, LLVM::Int1.type], LLVM::Int1.type)
    end

    private def boolean_unary_function_type
      @boolean_unary_function_type ||= LLVM::Type.function([LLVM::Int1.type], LLVM::Int1.type)
    end

    private def build_boolean_binary_body(func, instruction)
      func.basic_blocks.append("entry").build do |builder|
        result = builder.send(instruction, func.params[0], func.params[1], "bool_result") # rubocop:disable Style/Send
        builder.ret(result)
      end
    end

    private def build_boolean_unary_body(func, instruction)
      func.basic_blocks.append("entry").build do |builder|
        # NOT is implemented as XOR with TRUE (i.e., not(a) = a xor TRUE)
        # The instruction parameter should always be :xor for unary boolean operations
        result = builder.send(instruction, func.params[0], LLVM::TRUE, "not_result") # rubocop:disable Style/Send
        builder.ret(result)
      end
    end

    # Define the sum function: sum(i64, i64) -> i64.
    # Uses LLVM's sadd.with.overflow intrinsic for overflow detection.
    private def define_sum_function
      i64 = LLVM::Int64.type
      function_type = LLVM::Type.function([i64, i64], i64)
      @mod.functions.add("sum", function_type).tap { |func| build_sum_body(func) }
    end

    private def build_sum_body(func)
      func.basic_blocks.append("entry").build do |builder|
        intrinsic = sadd_with_overflow_intrinsic
        result = builder.call(intrinsic, func.params[0], func.params[1], "sadd_result")
        # TODO: Check for overflow (something like `builder.extract_value(result, 0) == 1`) and branch to return a Stone::Type::Error if true.
        # overflowed = builder.extract_value(result, 1)
        sum_value = builder.extract_value(result, 0, "sum")
        builder.ret(sum_value)
      end
    end

    private def sadd_with_overflow_intrinsic
      intrinsic_name = "llvm.sadd.with.overflow.i64"
      return @mod.functions[intrinsic_name] if @mod.functions[intrinsic_name]

      i64 = LLVM::Int64.type
      i1 = LLVM::Int1.type
      result_type = LLVM::Type.struct([i64, i1], false)
      function_type = LLVM::Type.function([i64, i64], result_type)
      @mod.functions.add(intrinsic_name, function_type)
    end

    # Define the if function: if(i1 condition, block* then_block, block* else_block) -> i64.
    # Takes a boolean condition and two block pointers, executes the appropriate block.
    private def define_if_function
      i1 = LLVM::Int1.type
      i64 = LLVM::Int64.type
      # Block type: () -> i64
      block_type = LLVM::Type.function([], i64)
      block_ptr = LLVM::Type.pointer(block_type)
      # if takes: (i1 condition, block* then_block, block* else_block) -> i64
      function_type = LLVM::Type.function([i1, block_ptr, block_ptr], i64)
      @mod.functions.add("if", function_type).tap { |func| build_if_body(func) }
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

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    private def register_builtin_function_types
      int = Stone::Type::Int
      bool = Stone::Type::Bool

      # sum(Int, Int) -> Int
      Stone::Type::Registry.register_as("sum", Stone::Type.function(param_types: [int, int], return_type: int))

      # if(Bool, Block, Block) -> Int
      # Note: Block type not yet in type system, so we just record param count conceptually
      Stone::Type::Registry.register_as("if", Stone::Type.function(param_types: [bool], return_type: int))

      # Boolean operators
      # and(Bool, Bool) -> Bool
      Stone::Type::Registry.register_as("and", Stone::Type.function(param_types: [bool, bool], return_type: bool))

      # or(Bool, Bool) -> Bool
      Stone::Type::Registry.register_as("or", Stone::Type.function(param_types: [bool, bool], return_type: bool))

      # xor(Bool, Bool) -> Bool
      Stone::Type::Registry.register_as("xor", Stone::Type.function(param_types: [bool, bool], return_type: bool))

      # not(Bool) -> Bool
      Stone::Type::Registry.register_as("not", Stone::Type.function(param_types: [bool], return_type: bool))

      # Equality operators: equals?(Any, Any) -> Bool
      any = Stone::Type::Any
      equality_type = Stone::Type.function(param_types: [any, any], return_type: bool)
      %w[equals? == != ≠].each do |name|
        Stone::Type::Registry.register_as(name, equality_type)
      end

      # Unicode operator aliases
      Stone::Type::Registry.register_as("∧", Stone::Type.function(param_types: [bool, bool], return_type: bool))
      Stone::Type::Registry.register_as("∨", Stone::Type.function(param_types: [bool, bool], return_type: bool))
      Stone::Type::Registry.register_as("⊻", Stone::Type.function(param_types: [bool, bool], return_type: bool))
      Stone::Type::Registry.register_as("¬", Stone::Type.function(param_types: [bool], return_type: bool))
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  end
end
