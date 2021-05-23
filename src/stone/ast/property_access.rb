module Stone

  module AST

    class PropertyAccess < Expression

      attr_reader :value
      attr_reader :property_name

      def initialize(value, property_name)
        @value = value
        @property_name = property_name.to_sym
        @source_location = get_source_location(value)
      end

      def evaluate(context)
        evaluated_value = value.evaluate(context)
        return evaluated_value if error?(evaluated_value)
        evaluated_value.property(property_name)
      end

      def to_s
        "#{value}.#{property_name}"
      end

    end

  end

end
