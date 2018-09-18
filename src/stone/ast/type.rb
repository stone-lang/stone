module Stone

  module AST

    class Type < Base

      attr_reader :name

      def initialize(name)
        @name = name
      end

      def type
        "Type"
      end

      def to_s
        name
      end

    end

  end

end
