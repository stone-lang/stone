require "stone/ast/expression"
require "stone/error/type_error"
require "stone/rtti"


module Stone
  class AST
    # TODO: Records should be first-class Type objects, not AST nodes.
    # When the type system is refactored:
    # - Record types should be instances of a RecordType class
    # - Record types should be global constants with properties
    # - Record types should have vtables for polymorphic operations
    # - Record instantiation should work like any other function call
    class RecordDefinition < Stone::AST::Expression

      attr_reader :fields
      attr_accessor :assigned_name

      # fields is an array of { name: "field_name", type: "TypeName" } hashes
      def initialize(fields)
        @name = :record_definition
        @fields = fields
        @assigned_name = nil
      end

      def to_llir(_builder, mod, scope = Stone::Scope.top_level)
        # Validate all field types resolve in current scope
        validate_field_types(scope, mod)
        # Generate the type constant for this record
        generate_type_constant(mod, scope) if @assigned_name
        # Generate and return a constructor function that creates instances of this record
        generate_constructor_function(mod, scope)
      end

      private def generate_type_constant(mod, scope)
        struct_type = llvm_type(mod, scope)
        size_bytes = calculate_struct_size(struct_type)
        Stone::RTTI.generate_record_type_constant(mod, @assigned_name, size_bytes, @fields)
      end

      private def calculate_struct_size(struct_type)
        # Calculate size based on field types (simplified - assumes packed alignment)
        total = 0
        struct_type.element_types.each do |elem_type|
          total += element_type_size(elem_type)
        end
        total
      end

      private def element_type_size(llvm_type)
        case llvm_type.kind
        when :integer then (llvm_type.width + 7) / 8  # Round up to bytes
        when :pointer then 8  # 64-bit pointers
        when :struct then llvm_type.element_types.sum { |t| element_type_size(t) }
        else 8  # Default to 8 bytes
        end
      end

      private def validate_field_types(scope, mod)
        @fields.each do |field|
          type_name = field[:type]
          next if type_name == @assigned_name # Self-reference is OK
          next if mod&.record_type?(type_name) # Record types are OK
          next if scope.lookup_type(type_name) # Scope resolution

          fail Stone::TypeError, "Unknown type: #{type_name}"
        end
      end

      def field_names
        @fields.map { |f| f[:name] }
      end

      def field_types
        @fields.map { |f| f[:type] }
      end

      def field_index(field_name)
        field_names.index(field_name)
      end

      def llvm_type(mod = nil, scope = Stone::Scope.top_level)
        # Convert field types to LLVM types
        llvm_field_types = @fields.map { |field| llvm_type_for_field(field[:type], mod, scope) }
        LLVM::Type.struct(llvm_field_types, false)
      end

      def to_s
        field_strs = @fields.map { |f| "#{f[:name]} :: #{f[:type]}" }
        "Record(#{field_strs.join(', ')})"
      end

      def type(_context = nil)
        return nil unless @assigned_name

        record_type = Stone::Type::Registry.lookup(@assigned_name)
        return nil unless record_type

        param_types = @fields.map { |f| Stone::Type::Registry.lookup(f[:type]) }
        return nil if param_types.any?(&:nil?)

        Stone::Type.function(param_types:, return_type: record_type)
      end

      # Returns the LLVM type for a field type name.
      # Uses Stone's type system for primitives, and ptr for record types.
      # Type parameters (from lambda scope) are treated as generic (ptr).
      private def llvm_type_for_field(type_name, mod, scope)
        # Check for self-reference (recursive type)
        return LLVM::Type.ptr if type_name == @assigned_name

        # Check for reference to another record type
        return LLVM::Type.ptr if mod&.record_type?(type_name)

        # Look up primitive types from Stone's type system
        stone_type = Stone::Type::Registry.lookup(type_name)
        return stone_type.llvm_type if stone_type

        # Check if type is defined in scope (e.g., type parameter from lambda)
        # Type parameters are treated as generic (ptr) at the LLVM level
        return LLVM::Type.ptr if scope.lookup_type(type_name)

        fail Stone::TypeError, "Unknown type: #{type_name}"
      end

      private def generate_constructor_function(mod, scope)
        func_name = "__record_constructor_#{object_id}__"
        func_type = constructor_function_type(mod, scope)

        mod.functions.add(func_name, func_type).tap do |func|
          build_constructor_body(func, mod, scope)
        end
      end

      private def constructor_function_type(mod, scope)
        # Constructor function signature: (field_types...) -> struct_type
        field_llvm_types = @fields.map { |field| llvm_type_for_field(field[:type], mod, scope) }
        LLVM::Type.function(field_llvm_types, llvm_type(mod, scope))
      end

      private def build_constructor_body(func, mod, scope)
        func.basic_blocks.append("entry").build do |builder|
          # Start with null/undef struct value
          struct_value = llvm_type(mod, scope).null

          # Insert each field value from function parameters
          @fields.each_with_index do |_field, index|
            struct_value = builder.insert_value(struct_value, func.params[index], index)
          end

          builder.ret(struct_value)
        end
      end

    end
  end
end
