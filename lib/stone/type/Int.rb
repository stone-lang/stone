I64 = LLVM::Int64.type

module Stone
  module Type
    class Int

      MIN = -(2**63)   # -9_223_372_036_854_775_808
      MAX = 2**63 - 1  # +9_223_372_036_854_775_807

      def llvm_type
        LLVM::Int64.type # i64
      end

    end
  end
end
