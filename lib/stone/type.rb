require "singleton"


module Stone
  # Type instance class - represents a type as an object rather than a class.
  # This is the new type system; Stone::Type module is the legacy class-based system.
  class TypeInstance

    attr_reader :name, :llvm_type, :fields
    attr_accessor :property_types

    def initialize(name:, llvm_type:, property_types: {}, fields: nil, primitive: false)
      @name = name
      @llvm_type = llvm_type
      @property_types = property_types
      @fields = fields
      @primitive = primitive
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

    def as_String
      name
    end

    def ==(other)
      other.is_a?(TypeInstance) && other.name == name
    end
    alias eql? ==

    def hash
      name.hash
    end

    def to_s
      name
    end

    def inspect
      "#<Stone::TypeInstance:#{name}>"
    end

    def self.primitive(name:, llvm_type:, property_types: {})
      new(name:, llvm_type:, property_types:, primitive: true)
    end

    def self.record(name:, fields:, llvm_type:)
      new(name:, llvm_type:, fields:, primitive: false)
    end

  end
end
