module Stone
  module Type
    class Bool

      FALSE = 0
      TRUE = 1

      def llvm_type
        LLVM::Int1.type # i1
      end

    end
  end
end
