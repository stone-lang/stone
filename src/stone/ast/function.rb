require "stone/top"
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

      def evaluate(_context)
        self
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

      # HACK: Treat some "well-known" functions as belonging to other classes.
      SPECIAL_FUNCTION_TYPES = {
        TRUE: "Boolean",
        FALSE: "Boolean",
      }
      SPECIAL_FUNCTION_NAMES = {
        TRUE: "Boolean.TRUE",
        FALSE: "Boolean.FALSE",
      }

      def type
        special_function_type || "Function"
      end

      def to_s(untyped: false)
        if type == "Function"
          "Function(#{parameters.join(", ")}) => {\n    #{body}\n}"
        else
          untyped ? special_function_name : "#{type}(#{special_function_name})"
        end
      end

      def normalized!
        self
      end

      def value
        self
      end

      private def special_function_type
        SPECIAL_FUNCTION_TYPES.each do |key, type|
          return type if self == Stone::Top::CONTEXT[key]
        end
        nil
      end

      private def special_function_name
        SPECIAL_FUNCTION_NAMES.each do |key, type|
          return type if self == Stone::Top::CONTEXT[key]
        end
        nil
      end

    end

  end

end
