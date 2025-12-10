module Stone
  module Type
    class Base

      def self.name
        fail NotImplementedError, "#{self} must implement .name"
      end

      def self.llvm_type
        fail NotImplementedError, "#{self} must implement .llvm_type"
      end

      def self.property_return_type(property_name)
        self::PROPERTY_TYPES[property_name]
      end

      def self.as_string
        name
      end

    end
  end
end
