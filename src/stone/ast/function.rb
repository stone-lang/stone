module Stone

  module AST

    class Function < Node

      attr_reader :parameters
      attr_reader :body

      def initialize(parameters, body)
        @source_location = parameters.first.line_and_column
        @body = body
        @parameters = parameters.map(&:to_sym)
      end

      def evaluate(context)
        @closure_context = context
        self
      end

      def call(parent_context, arguments) # rubocop:disable Metrics/AbcSize
        context = Hash.new{ |_h, k| parent_context[k] }
        parameters.zip(arguments).each do |param, arg|
          context[param] = arg
        end
        free_variables.each do |v|
          context[v] = @closure_context.fetch(v) { Error.new("UndefinedVariable", v) }
        end
        # puts "function called with context: #{context}"
        body.map{ |x| x.evaluate(context) }.compact.last
      end

      def arity
        Range.new(parameters.count, parameters.count)
      end

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

      override def children
        @body
      end

      # Get a list of all the variables defined *directly* in the body.
      private def defined_variables
        @defined_variables ||= @body.select{ |n| n.is_a?(Stone::AST::Assignment) }.map(&:name)
      end

      private def bound_variables
        parameters + defined_variables
      end

      private def free_variables
        variables_referenced - bound_variables
      end

    end

  end

end
