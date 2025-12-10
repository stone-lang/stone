require "llvm/core"


# Module for declaring C standard library functions in LLVM
module LibC

module_function

  def get_or_declare_strcmp(mod)
    return mod.functions["strcmp"] if mod.functions["strcmp"]

    # Declare strcmp: i32 strcmp(i8*, i8*)
    strcmp_type = LLVM::Type.function([LLVM::Type.pointer(LLVM::Int8), LLVM::Type.pointer(LLVM::Int8)], LLVM::Int32)
    mod.functions.add("strcmp", strcmp_type)
  end

end
