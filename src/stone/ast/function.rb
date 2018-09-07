module Stone

  module AST

    class Function < Base

      attr_reader :name
      attr_reader :parameters
      attr_reader :body

      def initialize(name, parameters, body)
        @source_location = name.line_and_column
        @name = name.to_s.to_sym
        @body = body
        @parameters = parameters.map(&:to_sym)
      end

      def evaluate(context)
        context[name] = self
        nil
      end

      def call(parent_context, arguments)
        context = Hash.new{ |_h, k| parent_context[k] }
        parameters.zip(arguments).each do |param, arg|
          context[param] = arg
        end
        body.map{ |x| x.evaluate(context) }.compact.last
      end

      def to_s
        "#{name}(#{parameters.join(", ")}) := {\n    #{body}\n}"
      end

    end

  end

end
