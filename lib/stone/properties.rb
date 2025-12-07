require "llvm/core"


module Stone
  module PropertyRegistry

    @properties = {}

    def self.register(type_name, property_name, &block)
      @properties[type_name] ||= {}
      @properties[type_name][property_name] = block
    end

    def self.lookup(type_name, property_name)
      @properties.dig(type_name, property_name)
    end

    # Register built-in Bool properties
    register("Bool", "not") do |builder, value|
      builder.not(value)
    end

    # Register built-in Int properties
    register("Int", "positive?") do |builder, value|
      builder.icmp(:sgt, value, LLVM::Int64.from_i(0))
    end

    register("Int", "negative?") do |builder, value|
      builder.icmp(:slt, value, LLVM::Int64.from_i(0))
    end

    register("Int", "zero?") do |builder, value|
      builder.icmp(:eq, value, LLVM::Int64.from_i(0))
    end

    # Register built-in String properties
    # NOTE: String.byte_count is handled specially in PropertyAccess#to_llir
    # for StringLiteral nodes (returns compile-time constant)
    register("String", "byte_count") do |_builder, _value|
      # For string references (not literals), we would need struct support
      # to extract the length field. For now, this is only used for type checking.
      fail "String.byte_count on string references not yet implemented"
    end

  end
end
