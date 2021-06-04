module Stone

  module AST

    class MethodCall < FunctionCall

      attr_reader :object
      attr_reader :arguments

      def initialize(object, method_name, arguments)
        @object = object
        @name = method_name.to_sym
        @arguments = arguments
        @source_location = get_source_location(object)
      end

      def evaluate(context) # rubocop:disable Metrics/AbcSize
        evaluated_object = object.evaluate(context)
        return error?(evaluated_object) if error?(evaluated_object)
        evaluated_arguments = arguments.map{ |a| a.evaluate(context) }
        return error?(evaluated_arguments) if error?(evaluated_arguments)
        method = evaluated_object.property(name)
        return arity_error(method, arguments.count) unless correct_arity?(method, arguments.count)
        method.call(context, evaluated_arguments)
      end

      def to_s
        "{object}.#{name}(#{arguments.join(', ')})"
      end

    end

  end

end
