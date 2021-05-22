module Stone

  module AST

    class Definition < Node

      attr_reader :name
      attr_reader :rvalue

      def initialize(name_slice, rvalue)
        @source_location = name_slice.line_and_column
        @name = name_slice.to_s.to_sym
        @rvalue = rvalue # This will be an AST::Expression.
      end

      def evaluate(context)
        context[name] = rvalue.evaluate(context)
        nil
      end

      def to_s
        "#{name} := #{rvalue}"
      end

      override def children
        [rvalue].flatten
      end

    end

  end

end
