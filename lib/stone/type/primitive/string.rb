module Stone
  class Type
    class Primitive < Type
      class String < Primitive

        def pointer_type?
          true
        end

      end
    end
  end
end
