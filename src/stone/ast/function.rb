module Stone

  module AST

    class Function < Base

      attr_reader :parameters
      attr_reader :body

      def initialize(parameters, body)
        @source_location = parameters.first.line_and_column
        @body = body
        @parameters = parameters.map(&:to_sym)
      end

      def evaluate(_context)
        self
      end

      def call(parent_context, arguments)
        context = Hash.new{ |_h, k| parent_context[k] }
        parameters.zip(arguments).each do |param, arg|
          context[param] = arg
        end
        body.map{ |x| x.evaluate(context) }.compact.last
      end

      def arity
        parameters.count
      end

      def to_s
        "(#{parameters.join(", ")}) => {\n    #{body}\n}"
      end

    end

  end

end
