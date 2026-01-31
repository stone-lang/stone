module Stone
  class Type
    class Primitive < Type
      class Boolean < Primitive

        def size_bytes
          1
        end

        def alignment
          1
        end

        def payload_llvm_type
          LLVM::Int1.type
        end

      end
    end
  end
end
