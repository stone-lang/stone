module Stone

  module AST

    class VariableReference < Expression

      attr_reader :name

      def initialize(name)
        @source_location = name.line_and_column
        @name = name.to_s.to_sym
      end

      def evaluate(context)
        context[name] || Builtin::Error.new("UndefinedVariable", name)
      end

      def to_s
        name.to_s
      end

    end

  end

end
