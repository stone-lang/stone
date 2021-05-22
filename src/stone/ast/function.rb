module Stone

  module AST

    class Function < Expression

      attr_reader :parameters
      attr_reader :body

      def initialize(parameters, body)
        @source_location = parameters.first.line_and_column
        @body = body
        @parameters = parameters.map(&:to_sym)
      end

      def evaluate(_context)
        self # TODO: create a Builtin::Function.
      end

      def call(parent_context, arguments)
        context = Hash.new{ |_h, k| parent_context[k] }
        parameters.zip(arguments).each do |param, arg|
          context[param] = arg
        end
        body.filter_map{ |x| x.evaluate(context) }.last
      end

      def arity
        Range.new(parameters.count, parameters.count)
      end

      # TODO: This needs to go away when we generate a Builtin::Function Value.
      def type
        "Function"
      end

      def to_s(_untyped: false)
        "Function(#{parameters.join(", ")}) => {\n    #{body}\n}"
      end

      def normalized!
        self
      end

      def value
        self
      end

    end

  end

end
