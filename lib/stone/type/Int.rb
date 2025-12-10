require "llvm/core"
require "stone/type/base"

I64 = LLVM::Int64.type

module Stone
  module Type
    class Int < Base

      MIN = -(2**63)   # -9_223_372_036_854_775_808
      MAX = 2**63 - 1  # +9_223_372_036_854_775_807

      PROPERTY_TYPES = {}

      def self.name
        "Int"
      end

      def self.llvm_type
        LLVM::Int64.type # i64
      end

      def llvm_type
        self.class.llvm_type
      end

    end
  end
end
