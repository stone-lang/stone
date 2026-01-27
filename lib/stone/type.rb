module Stone
  # Value object representing a type in the Stone language.
  # Each type (Int, Bool, String, etc.) is a singleton instance registered in TypeRegistry.
  # Access via Stone::Type::Int, Stone::Type::Bool, etc.
  class Type

    # Size in bytes for primitive types, used for union payload sizing
    PRIMITIVE_SIZES = {
      "Int" => 8,
      "Bool" => 1,
      "String" => 8,  # pointer size
      "Null" => 0,
      "Type" => 8,    # pointer size
      "FieldList" => 8  # pointer size
    }.freeze

    # Alignment requirements for primitive types
    PRIMITIVE_ALIGNMENTS = {
      "Int" => 8,
      "Bool" => 1,
      "String" => 8,  # pointer alignment
      "Null" => 1,
      "Type" => 8,    # pointer alignment
      "FieldList" => 8  # pointer alignment
    }.freeze

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
      @property_types[property_name] || field_type(property_name)
    end

    private def field_type(field_name)
      return nil unless @fields

      field = @fields.find { |f| f[:name] == field_name }
      return nil unless field

      Stone::AST::FieldHelpers.resolve_field_type(field)
    end

    def primitive?
      @primitive
    end

    def record?
      !@primitive && !@fields.nil?
    end

    def size_bytes
      return PRIMITIVE_SIZES[@name] if primitive? && PRIMITIVE_SIZES.key?(@name)
      # Records are stored as pointers in unions (to avoid infinite recursion with recursive types)
      return 8 if record?  # pointer size
      return 8 if function?  # function pointer

      8  # default
    end

    def alignment
      return PRIMITIVE_ALIGNMENTS[@name] if primitive? && PRIMITIVE_ALIGNMENTS.key?(@name)
      # Records are stored as pointers in unions
      return 8 if record?  # pointer alignment

      8  # default pointer alignment
    end

    def pointer_type?
      %w[String Null].include?(@name) || record?
    end

    def payload_llvm_type
      case @name
      when "Null" then LLVM::Type.pointer
      when "Int" then LLVM::Int64.type
      when "Bool" then LLVM::Int1.type
      when "String" then LLVM::Type.pointer
      else LLVM::Type.pointer  # records and other pointer types
      end
    end

    def function?
      @param_types.is_a?(Array)
    end

    def union?
      false
    end

    def nullable?
      false
    end

    def non_null_type
      self
    end

    def compatible_with?(other)
      return true if self == other
      return other.alternatives.any? { |alt| compatible_with?(alt) } if other.union?

      function? && function_compatible_with?(other)
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
      return_name = return_type.function? ? "(#{return_type.name})" : return_type.name
      name = "(#{param_names}) -> #{return_name}"
      new(name:, llvm_type: nil, param_types:, return_type:)
    end

    def self.union(alternatives:)
      union = Union.new(alternatives:)
      union.alternatives.length == 1 ? union.alternatives.first : union
    end

    # Union type - represents a value that can be one of several types
    class Union < Type
      attr_reader :alternatives

      def initialize(alternatives:)
        @alternatives = flatten_and_dedupe(alternatives)
        fail ::ArgumentError, "Union type requires at least one alternative" if @alternatives.empty?

        super(name: generate_name, llvm_type: create_variable_sized_llvm_type)
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
        # Use pointer only if ALL non-null alternatives are pointer types.
        # Otherwise use i64 (integers can be widened, Null becomes 0).
        non_null_alts = @alternatives.reject { |alt| alt.name == "Null" }
        return LLVM::Int64.type if non_null_alts.empty?

        all_pointers = non_null_alts.all?(&:pointer_type?)
        all_pointers ? LLVM::Type.pointer : LLVM::Int64.type
      end

      private def create_variable_sized_llvm_type
        payload_array = LLVM::Type.array(LLVM::Int8.type, payload_size)
        LLVM::Type.struct([LLVM::Type.pointer, payload_array], false)
      end

      def union?
        true
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

      def nullable?
        @alternatives.any? { |t| null_type?(t) }
      end

      def non_null_type
        remaining = @alternatives.reject { |t| null_type?(t) }
        return remaining.first if remaining.length == 1

        Stone::Type.union(alternatives: remaining)
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
        flattened = types.flat_map { |t| t.union? ? t.alternatives : [t] }
        flattened.uniq
      end

      private def null_type?(type)
        type.name == "Null"
      end
    end

  end

  # Backwards compatibility alias (deprecated - use Stone::Type directly)
  TypeInstance = Type
end
