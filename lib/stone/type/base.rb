# TODO: Types should be **instances** of Stone::Type, **not** subclasses.
# That will allow us to more easily include them in Stone as constants.


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

      def self.as_String
        name
      end

      def self.bit_width
        fail NotImplementedError, "#{self} must implement .bit_width"
      end

      def self.primitive?
        false  ## NOTE: Overridden for primitive types
      end

      def self.pointer?
        fail NotImplementedError, "#{self} must implement .pointer?"
      end
    end
  end
end
