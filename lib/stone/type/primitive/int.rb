module Stone
  class Type
    class Primitive < Type
      class Int < Primitive

        def payload_llvm_type
          LLVM::Int64.type
        end

      end
    end
  end
end
