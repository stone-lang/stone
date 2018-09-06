module Stone

  module AST

    class Assignment < Base

      attr_reader :name
      attr_reader :rvalue

      def initialize(name_slice, rvalue)
        @source_location = name_slice.line_and_column
        @name = name_slice.to_s.to_sym
        @rvalue = rvalue
      end

      def evaluate(context)
        context[name] = rvalue.evaluate(context)
        nil
      end

      def to_s
        "#{name} := #{rvalue}"
      end

    end

  end

end
