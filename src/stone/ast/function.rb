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

      def evaluate(context)
        @body = body.map{ |stmt|
          stmt.recursively{ |ast_node|
            if ast_node.is_a?(VariableReference) && !defined_locally?(ast_node.name)
              ast_node.evaluate(context)
            else
              ast_node
            end
          }
        }
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
        Range.new(parameters.count, parameters.count)
      end

      def to_s
        "(#{parameters.join(", ")}) => {\n    #{body}\n}"
      end

      def defined_locally?(name)
        parameters.include?(name) || body.any?{ |stmt| stmt.is_a?(Assignment) && stmt.name == name }
      end

    end

  end

end
