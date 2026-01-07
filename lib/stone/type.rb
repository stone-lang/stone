module Stone
  # Value object representing a type in the Stone language.
  # Each type (Int, Bool, String, etc.) is a singleton instance registered in TypeRegistry.
  # Access via Stone::Type::Int, Stone::Type::Bool, etc.
  class Type

    attr_reader :name, :llvm_type, :fields, :min, :max, :param_types, :return_type
    attr_accessor :property_types

    def initialize(name:, llvm_type:, property_types: {}, fields: nil, **options)
      @name = name
      @llvm_type = llvm_type
      @property_types = property_types
      @fields = fields
      @primitive = options[:primitive] || false
      @min = options[:min]
      @max = options[:max]
      @param_types = options[:param_types]
      @return_type = options[:return_type]
    end

    def property_return_type(property_name)
      @property_types[property_name]
    end

    def primitive?
      @primitive
    end

    def record?
      !@primitive && !@fields.nil?
    end

    def function?
      @param_types.is_a?(Array)
    end

    def as_String
      name
    end

    def ==(other)
      other.is_a?(self.class) && other.name == name
    end
    alias eql? ==

    def hash
      name.hash
    end

    def to_s
      name
    end

    def inspect
      "#<Stone::Type:#{name}>"
    end

    def self.primitive(name:, llvm_type:, property_types: {}, min: nil, max: nil)
      new(name:, llvm_type:, property_types:, primitive: true, min:, max:)
    end

    def self.record(name:, fields:, llvm_type:)
      new(name:, llvm_type:, fields:, primitive: false)
    end

    def self.function(param_types:, return_type:)
      param_names = param_types.map(&:name).join(", ")
      name = "(#{param_names}) -> #{return_type.name}"
      new(name:, llvm_type: nil, param_types:, return_type:)
    end

  end

  # Backwards compatibility alias (deprecated - use Stone::Type directly)
  TypeInstance = Type
end
