module Stone

  module AST

    class PropertyAccess < Base

      attr_reader :object
      attr_reader :property_name

      def initialize(object, property_name)
        @object = object
        @property_name = property_name.to_sym
        @source_location = get_source_location(object)
      end

      def evaluate(context)
        evaluated_object = object.evaluate(context)
        return evaluated_object if error?(evaluated_object)
        property_value = evaluated_object.properties[property_name]
        if property_value.nil?
          Error.new("InvalidProperty", property_name.to_s)
        else
          property_value
        end
      end

      def to_s
        "#{object}.#{property_name}"
      end

    end

  end

end
