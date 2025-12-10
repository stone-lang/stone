require "llvm/core"
require "stone/type/base"


module Stone
  module Type
    class String < Base

      PROPERTY_TYPES = {}

      def self.name
        "String"
      end

      def self.llvm_type
        # String is represented as a struct { ptr, i64 } (pointer to data, length)
        LLVM::Type.struct([LLVM::Type.pointer(LLVM::Int8), LLVM::Int64], false)
      end

    end
  end
end
