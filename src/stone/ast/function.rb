module Stone

  module AST

    class Function < Base

      attr_reader :name
      attr_reader :parameters
      attr_reader :body

      def initialize(name, parameters, body)
        @name = name.to_s.to_sym
        @body = body
        @parameters = parameters.map(&:to_sym)
      end

      def evaluate(context)
        context[name] = self
        nil
      end

      def call(arguments)
        context = {}
        parameters.zip(arguments).each{ |param, arg| context[param] = arg }
        body.evaluate(context)
      end

      def to_s
        "#{name}(#{parameters.join(", ")}) := {\n    #{body}\n}"
      end

    end

  end

end
