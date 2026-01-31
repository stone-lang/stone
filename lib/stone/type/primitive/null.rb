module Stone
  class Type
    class Primitive < Type
      class Null < Primitive

        def size_bytes
          0
        end

        def alignment
          1
        end

        def pointer_type?
          true
        end

      end
    end
  end
end
