require "extensions/enumerable"


module Stone

  module Builtin

    class Pair < Value

      attr_reader :first
      attr_reader :second

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

      PROPERTIES = {
        first: lambda(&:first),
        second: lambda(&:second),
        last: lambda(&:second),
        left: lambda(&:first),
        right: lambda(&:second),
        key: lambda(&:first),
        value: lambda(&:second),
      }

      def to_s(*)
        "#{type}(#{@first.to_s(untyped: true)}, #{@second.to_s(untyped: true)})"
      end

      override def children
        [@first, @second]
      end

      def child_types
        [@first.type, @second.type]
      end

    end

  end

end
