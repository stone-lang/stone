module Stone
  class Type
    class Record < Type

      def initialize(name:, fields:, llvm_type:, property_types: {}, **options)
        super(name:, llvm_type:, fields:, property_types:, **options)
      end

      def record?
        true
      end

      def pointer_type?
        true
      end

      def payload_llvm_type
        LLVM::Type.pointer
      end

      def field_index(field_name)
        return nil unless @fields

        @fields.index { |f| f.name == field_name }
      end

      def field_type_annotation(field_name)
        return nil unless @fields

        field = @fields.find { |f| f.name == field_name }
        field&.type_annotation
      end

      def property_return_type(property_name)
        @property_types[property_name] || field_type(property_name)
      end

      private def field_type(field_name)
        return nil unless @fields

        field = @fields.find { |f| f.name == field_name }
        return nil unless field

        field.resolve_type
      end

    end
  end
end
