require "extensions/enumerable"


module Stone

  module AST

    class Pair < Object

      def initialize(first, second, type_specifier: [Any, Any])
        @first = first
        @second = second
        @type_specifier = type_specifier
        super([first, second])
      end

      def type
        "Pair[#{type_specifier.first}, #{type_specifier.last}]"
      end

      def type_specifier
        if @type_specifier == [Any, Any]
          child_types
        else
          @type_specifier
        end
      end

      def properties
        @properties ||= {
          first: @first,
          second: @second,
          last: @second,
          left: @first,
          right: @second,
          key: @first,
          value: @second
        }
      end

      def methods
        @methods ||= {
        }
      end

      def to_s
        "#{type}(#{@first}, #{@second})"
      end

      def children
        [@first, @second]
      end

      def child_types
        [@first.type, @second.type]
      end

    end

  end

end
