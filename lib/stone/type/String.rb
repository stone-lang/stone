require "llvm/core"


module Stone
  module Type
    class String

      def self.llvm_type
        # String is represented as a struct { ptr, i64 } (pointer to data, length)
        LLVM::Type.struct([LLVM::Type.pointer(LLVM::Int8), LLVM::Int64], false)
      end

    end
  end
end
