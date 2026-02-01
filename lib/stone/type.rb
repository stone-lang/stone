require "stone/type/record/field"

module Stone
  # Base class representing a type in the Stone language.
  # Subclasses: Primitive, Record, Function, Union.
  # Each built-in type is a singleton instance registered in TypeRegistry.
  # Access via Stone::Type::Int, Stone::Type::Bool, etc.
  class Type

    attr_reader :name, :llvm_type, :fields, :min, :max, :param_types, :return_type, :generic_for
    attr_accessor :property_types

    def initialize(name:, llvm_type:, property_types: {}, fields: nil, **options)
      @name = name
      @llvm_type = llvm_type
      @property_types = property_types
      @fields = fields
      @min = options[:min]
      @max = options[:max]
      @param_types = options[:param_types]
      @return_type = options[:return_type]
      @generic_for = options[:generic_for]
    end

    def property_return_type(property_name)
      @property_types[property_name]
    end

    def primitive?
      false
    end

    def record?
      false
    end

    def function?
      false
    end

    def union?
      false
    end

    def generic?
      false
    end

    def nullable?
      false
    end

    def non_null_type
      self
    end

    def size_bytes
      8
    end

    def alignment
      8
    end

    def pointer_type?
      false
    end

    def payload_llvm_type
      LLVM::Type.pointer
    end

    def compatible_with?(other)
      return true if self == other
      return true if covers_category?(other)
      return other.alternatives.any? { |alt| compatible_with?(alt) } if other.union?

      function? && function_compatible_with?(other)
    end

    private def covers_category?(other)
      (@generic_for == :record && other.record?) || (@generic_for == :function && other.function?)
    end

    private def function_compatible_with?(other)
      return false unless other.function?
      return false unless param_types.length == other.param_types.length

      params_compatible?(other) && return_type.compatible_with?(other.return_type)
    end

    private def params_compatible?(other)
      param_types.zip(other.param_types).all? { |a, b| a.compatible_with?(b) }
    end

    def as_String
      name
    end

    def ==(other)
      other.is_a?(Stone::Type) && other.name == name
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

    # Factory methods delegate to subclasses
    def self.primitive(name:, llvm_type:, property_types: {}, **options)
      klass = primitive_class_for(name)
      klass.new(name:, llvm_type:, property_types:, **options)
    end

    def self.record(name:, fields:, llvm_type:)
      Record.new(name:, fields:, llvm_type:)
    end

    def self.function(param_types:, return_type:)
      param_names = param_types.map(&:name).join(", ")
      return_name = return_type.function? ? "(#{return_type.name})" : return_type.name
      fn_name = "(#{param_names}) -> #{return_name}"
      Function.new(name: fn_name, param_types:, return_type:)
    end

    def self.union(alternatives:, name: nil, generic_base_name: nil)
      union = Union.new(alternatives:, name:, generic_base_name:)
      return union if name

      union.alternatives.length == 1 ? union.alternatives.first : union
    end

    def self.primitive_class_for(name)
      case name
      when "Int" then Primitive::Int
      when "Bool" then Primitive::Boolean
      when "String" then Primitive::String
      when "Null" then Primitive::Null
      when "Type" then Primitive::TypeType
      else Primitive
      end
    end
    private_class_method :primitive_class_for

    # Union type - represents a value that can be one of several types
    class Union < Type
      attr_reader :alternatives, :generic_base_name

      def initialize(alternatives:, name: nil, generic_base_name: nil)
        @alternatives = flatten_and_dedupe(alternatives)
        @generic_base_name = generic_base_name
        fail ::ArgumentError, "Union type requires at least one alternative" if @alternatives.empty?

        super(name: name || generate_name, llvm_type: create_variable_sized_llvm_type)
      end

      def size_bytes
        8 + payload_size  # tag pointer (8 bytes) + payload
      end

      def alignment
        # Union alignment is max of pointer alignment and payload alignment
        [8, payload_alignment].max
      end

      def payload_size
        @alternatives.map(&:size_bytes).max || 0
      end

      def payload_alignment
        @alternatives.map(&:alignment).max || 1
      end

      def common_llvm_result_type
        # Determine best common type for phi merge without int2ptr/ptr2int conversions.
        # - If ALL non-null alternatives are pointers, use pointer
        # - If ALL non-null alternatives are integers, use i64
        # - For MIXED types, return nil (caller should not extract, return union as-is)
        non_null_alts = @alternatives.reject { |alt| alt.name == "Null" }
        return LLVM::Int64.type if non_null_alts.empty?

        all_pointers = non_null_alts.all?(&:pointer_type?)
        all_integers = non_null_alts.all? { |alt| %w[Int Bool].include?(alt.name) }

        return LLVM::Type.pointer if all_pointers
        return LLVM::Int64.type if all_integers

        nil # Mixed types - don't extract
      end

      def homogeneous?
        # Returns true if all non-null alternatives have compatible LLVM types
        !common_llvm_result_type.nil?
      end

      # Returns true if the union contains types that cannot be distinguished by value alone.
      # For example, Bool | Int - both are integers, and Bool(1) looks like Int(1).
      # Such unions require returning the runtime type tag to Ruby for proper interpretation.
      def needs_runtime_type_tag?
        non_null_names = @alternatives.reject { |alt| alt.name == "Null" }.map(&:name)
        non_null_names.include?("Bool") && non_null_names.include?("Int")
      end

      private def create_variable_sized_llvm_type
        payload_array = LLVM::Type.array(LLVM::Int8.type, payload_size)
        LLVM::Type.struct([LLVM::Type.pointer, payload_array], false)
      end

      def union?
        true
      end

      def nullable?
        @alternatives.any? { |t| null_type?(t) }
      end

      # Look through non-null alternatives for a property.
      # Returns the property type if ALL non-null alternatives have it with the same type.
      # This enables chained access like `o.value.x` where `value` is `Point | Null`.
      def property_return_type(property_name)
        non_null_alts = @alternatives.reject { |alt| null_type?(alt) }
        return nil if non_null_alts.empty?

        # Get property type from each non-null alternative
        prop_types = non_null_alts.map { |alt| alt.property_return_type(property_name) }

        # All alternatives must have this property
        return nil if prop_types.any?(&:nil?)

        # For now, require all alternatives to return the same type
        # (Future: could return a union of the return types)
        return nil unless prop_types.uniq.length == 1

        prop_types.first
      end

      def non_null_type
        remaining = @alternatives.reject { |t| null_type?(t) }
        return remaining.first if remaining.length == 1

        Stone::Type.union(alternatives: remaining)
      end

      # Find the first Record alternative whose field count matches the given count.
      # NOTE: If multiple Record alternatives have the same field count, this picks the first.
      # A future improvement could use type checking to disambiguate.
      def find_record_alternative_by_field_count(field_count)
        @alternatives.select(&:record?).find { |alt| alt.fields.length == field_count }
      end

      def compatible_with?(other)
        other.union? ? covers_all_alternatives?(other) : includes_compatible_type?(other)
      end

      private def covers_all_alternatives?(union)
        union.alternatives.all? { |alt| includes_compatible_type?(alt) }
      end

      private def includes_compatible_type?(type)
        @alternatives.any? { |t| t.compatible_with?(type) }
      end

      def ==(other)
        return false unless other.is_a?(Union)

        Set.new(@alternatives) == Set.new(other.alternatives)
      end
      alias eql? ==

      def hash
        Set.new(@alternatives).hash
      end

      private def generate_name
        names = @alternatives.map(&:name)
        non_null = names.reject { |n| n == "Null" }.sort
        null = names.select { |n| n == "Null" }
        (non_null + null).join(" | ")
      end

      private def flatten_and_dedupe(types)
        flattened = types.compact.flat_map { |t| t.union? ? t.alternatives : [t] }
        flattened.uniq
      end

      private def null_type?(type)
        type.name == "Null"
      end
    end

  end

end

require "stone/type/primitive"
require "stone/type/primitive/int"
require "stone/type/primitive/boolean"
require "stone/type/primitive/string"
require "stone/type/primitive/null"
require "stone/type/primitive/type_type"
require "stone/type/record"
require "stone/type/function"
require "stone/type/generic"
