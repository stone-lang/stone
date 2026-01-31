require "stone/ast"
require "stone/ast/program_unit/top_function"
require "stone/built_ins"
require "llvm/core"
require "llvm/execution_engine"


module Stone
  class AST
    class ProgramUnit < Stone::AST

      def initialize(children)
        super(:program_unit, children)
        @top_function = TopFunction.new(children)
        LLVM.init_jit
      end

      def to_llir
        module_ref
      end

      def eval(function_name = "__top__")
        result, result_type = run_function(global_function(function_name))
        convert_to_ruby(result, result_type)
      ensure
        jit_engine&.dispose
      end

      private def run_function(func)
        result = jit_engine.run_function(func)
        [result, last_expression_type]
      end

      # Determine the Stone type of the last expression for proper Ruby conversion
      # Must match the logic in TopFunction#compute_return_type
      private def last_expression_type
        last_child = children&.last
        return :null unless last_child

        # Check for heap-allocated union field access first (e.g., Bool | Int)
        # These return a pointer to heap memory containing the union struct
        return :heap_union_ptr if heap_union_field_access?(last_child)

        # Check for mixed union field access (PropertyAccess on mixed union field)
        # Mixed unions now return i64 (payload extracted directly)
        return :mixed_union_value if mixed_union_field_access?(last_child)

        # Check for homogeneous union field access
        return :union_value if union_field_access?(last_child)

        # Check for string-returning properties (Type.as_String, FieldList.name)
        return :string if string_returning_property?(last_child)

        # Use the Stone type system for everything else
        # Rescue errors since computed properties may not be registered in type system
        stone_type = safe_get_type(last_child)
        stone_type_to_result_type(stone_type)
      end

      private def lookup_type_declaration(identifier)
        type_decl = children&.find { |c|
          c.is_a?(Stone::AST::TypeDeclaration) && c.identifier == identifier
        }
        return nil unless type_decl

        type_decl.type_annotation.to_type(Stone::TypeRegistry.instance)
      end

      # NOTE: No scope available in eval phase; passes raw module_ref.
      # TypeContext migration will happen when scope is threaded through ProgramUnit.
      private def safe_get_type(node)
        node.type(module_ref)
      rescue Stone::PropertyError, Stone::TypeError
        # Type couldn't be determined (computed properties, etc.) - default to nil (becomes i64)
        nil
      end

      # PropertyAccess patterns that return string pointers
      private def string_returning_property?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)

        property = node.property
        # Type.as_String returns a string pointer
        return true if property == "as_String"
        # FieldList.name returns a string pointer
        return true if property == "name"

        false
      end

      private def stone_type_to_result_type(stone_type)
        # Default to i64 for unknown types (matches original behavior where all values were i64)
        return :i64 unless stone_type

        # Handle union types
        return union_result_type(stone_type) if stone_type.is_a?(Stone::Type::Union)

        case stone_type.name
        when "Null" then :null
        when "Bool" then :boolean
        when "Int" then :i64
        when "String" then :string
        else :pointer  # Records and other pointer types
        end
      end

      private def union_result_type(_union_type)
        # All union variables return the union struct, which is extracted by MixedUnionExtractor
        :mixed_union_ptr
      end

      private def heap_union_field_access?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)
        return false unless node.union_field_access?(module_ref)

        union_type = get_union_type_for_property_access(node)
        union_type&.needs_runtime_type_tag?
      end

      private def mixed_union_field_access?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)
        return false unless node.union_field_access?(module_ref)

        union_type = get_union_type_for_property_access(node)
        union_type && !union_type.homogeneous?
      end

      private def union_field_access?(node)
        return false unless node.is_a?(Stone::AST::PropertyAccess)

        node.union_field_access?(module_ref)
      end

      RESULT_CONVERTERS = {
        "i64" => ->(r, _) { r.to_i },
        "boolean" => ->(r, _) { r.to_i != 0 },
        "null" => ->(_r, _) { nil },
        "pointer" => ->(r, _) { r.to_value_ptr.to_i }
      }.freeze

      # Convert JIT result to Ruby value based on result type.
      # - i64 results use result.to_i
      # - ptr results use result.to_value_ptr (not to_ptr!)
      private def convert_to_ruby(result, result_type)
        converter = RESULT_CONVERTERS[result_type.to_s]
        return converter.call(result, self) if converter

        convert_complex_result(result, result_type)
      end

      private def convert_complex_result(result, result_type)
        case result_type.to_s
        when "string" then read_string_from_pointer(result.to_value_ptr.to_i)
        when "union_value" then convert_union_value_to_ruby(result.to_i)
        when "mixed_union_value" then convert_mixed_union_value(result.to_i)
        when "heap_union_ptr" then convert_heap_union_ptr(result.to_value_ptr.to_i)
        else fail "Don't know how to convert result type to Ruby: #{result_type}"
        end
      end

      private def convert_heap_union_ptr(ptr_addr)
        return nil if ptr_addr.zero?

        last_child = children&.last
        union_type = get_union_type_for_property_access(last_child)
        return nil unless union_type

        HeapUnionConverter.new(ptr_addr, union_type).convert
      end

      private def convert_union_value_to_ruby(value)
        # Get the union type to determine how to interpret the value
        last_child = children&.last
        return value unless last_child.is_a?(Stone::AST::PropertyAccess)

        union_type = get_union_type_for_property_access(last_child)
        return value unless union_type

        convert_based_on_union_type(value, union_type)
      end

      private def convert_mixed_union_value(value)
        last_child = children&.last
        union_type = get_union_type_for_last_child(last_child)
        return value unless union_type

        MixedUnionValueConverter.new(value, union_type).convert
      end

      private def get_union_type_for_last_child(node)
        case node
        when Stone::AST::PropertyAccess
          get_union_type_for_property_access(node)
        when Stone::AST::Reference
          # For References, look up the type declaration
          lookup_type_declaration(node.identifier)
        end
      end

      private def get_union_type_for_property_access(property_access)
        record_type_name = property_access.get_record_type_name(module_ref)
        return nil unless record_type_name

        record_type = Stone::Type::Registry.lookup(record_type_name)
        return nil unless record_type&.record?

        annotation = record_type.field_type_annotation(property_access.property)
        return nil unless Stone::AST::FieldHelpers.union_annotation?(annotation)

        annotation.to_type(Stone::Type::Registry)
      end

      private def convert_based_on_union_type(value, union_type)
        UnionValueConverter.new(value, union_type).convert
      end

      # Converts heap-allocated union structs to Ruby values using the runtime type tag.
      # The union struct layout is: { ptr type_tag, [N x i8] payload }
      # The type_tag is a pointer to a Stone::Type constant. We read the type name from it.
      class HeapUnionConverter
        TYPE_TAG_SIZE = 8  # Size of the type tag pointer (first field in union struct)

        def initialize(union_ptr_addr, union_type)
          @union_ptr = FFI::Pointer.new(union_ptr_addr)
          @union_type = union_type
        end

        def convert
          type_name = read_type_name_from_tag
          read_and_convert_payload(type_name)
        end

        private def read_type_tag_ptr
          # Type tag is at offset 0, it's a pointer to Stone::Type struct
          @union_ptr.read_pointer
        end

        private def payload_ptr
          @union_ptr + TYPE_TAG_SIZE
        end

        # Read the type name string from the type tag struct.
        # Stone::Type struct layout: { ptr name, i64 size, i8 kind, ptr fields }
        # The name field (offset 0) is a pointer to a null-terminated string.
        private def read_type_name_from_tag
          type_tag_ptr = read_type_tag_ptr
          return "Null" if type_tag_ptr.null?

          # Read the name pointer (first field of Stone::Type struct)
          name_ptr = type_tag_ptr.read_pointer
          return "Unknown" if name_ptr.null?

          # Read the null-terminated string
          name_ptr.read_string
        end

        # Read payload with the correct size based on type, then convert to Ruby
        private def read_and_convert_payload(type_name)
          case type_name
          when "Null" then nil
          when "Bool" then payload_ptr.read_uint8 != 0
          when "Int" then payload_ptr.read_int64
          when "String" then read_string(payload_ptr.read_pointer.to_i)
          else payload_ptr.read_int64  # Records and other pointer types
          end
        end

        private def read_string(ptr_addr)
          return "" if ptr_addr.zero?

          FFI::Pointer.new(ptr_addr).read_string.force_encoding(Encoding::UTF_8)
        end
      end

      # Converts raw i64 values from LLVM to Ruby values based on union type alternatives.
      # NOTE: This is a temporary solution until proper runtime type dispatch is implemented.
      # The limitation is that Int(0) in Int | Null will return nil, not 0.
      class UnionValueConverter
        def initialize(value, union_type)
          @value = value
          @alternatives = union_type.alternatives
        end

        def convert
          return nil if null_value?
          return convert_string if string_only?
          return convert_record if record_only?
          return @value if has?("Int")
          return @value != 0 if has?("Bool")

          @value
        end

        private def null_value? = @value.zero? && has?("Null")
        private def string_only? = has?("String") && !has?("Int") && !has?("Bool") && !any_record?
        private def record_only? = any_record? && !has?("Int") && !has?("Bool") && !has?("String")
        private def has?(name) = @alternatives.any? { |alt| alt.name == name }
        private def any_record? = @alternatives.any?(&:record?)

        private def convert_string
          return "" if @value.zero?

          FFI::Pointer.new(@value).read_string.force_encoding(Encoding::UTF_8)
        end

        private def convert_record
          return nil if @value.zero?

          # Returns raw pointer value. Chained property access (e.g., o.value.x)
          # requires compile-time handling in PropertyAccess, not Ruby conversion.
          @value
        end
      end

      # Converts raw i64 payload values from mixed unions to Ruby values.
      # For mixed unions (e.g., Int | String), the payload is extracted as i64.
      # Without runtime type tag access, we use heuristics based on the alternatives:
      # - If Int is an alternative, and value looks like a valid Int, return as Int
      # - If String is an alternative, and value looks like a pointer, read as String
      # NOTE: This has limitations - we can't distinguish Int(0) from NULL, or
      # a small Int that happens to look like a valid pointer address.
      class MixedUnionValueConverter
        def initialize(value, union_type)
          @value = value
          @alternatives = union_type.alternatives
        end

        def convert
          return nil if null_value?
          return convert_int_or_string if has?("Int") && has?("String")

          convert_single_type
        end

        private def null_value? = @value.zero? && has?("Null")

        private def convert_int_or_string
          looks_like_pointer? ? read_string : @value
        end

        private def convert_single_type
          return @value if has?("Int")
          return @value != 0 if has?("Bool")
          return read_string if has?("String")

          @value
        end

        private def has?(name) = @alternatives.any? { |alt| alt.name == name }

        private def looks_like_pointer?
          # Heuristic: heap pointers are typically large addresses, aligned to 8 bytes
          # Small values (< 0x1000) are likely integers
          # This is imperfect but works for common cases
          @value > 0x1000 && (@value % 8).zero?
        end

        private def read_string
          return "" if @value.zero?

          FFI::Pointer.new(@value).read_string.force_encoding(Encoding::UTF_8)
        end
      end

      private def read_string_from_pointer(ptr_addr)
        return "" if ptr_addr.zero?

        FFI::Pointer.new(ptr_addr).read_string.force_encoding(Encoding::UTF_8)
      end

      private def jit_engine
        @jit_engine ||= LLVM::JITCompiler.new(module_ref)
      end

      private def global_function(function_name)
        module_ref.functions[function_name]
      end

      private def module_ref
        @module_ref ||= create_module
      end

      private def create_module
        LLVM::Module.new("__program_unit__").tap do |mod|
          scope = Stone::Scope.top_level
          Stone::BuiltIns.new(mod, scope).setup
          generate_top_function(mod, scope)
        end
      end

      # Generate IR for all code that's directly in the module.
      # TODO: Maybe pass in `ARGV` and `ENV`.
      # ... for `ARGV`, we'll probably need to implement `main(argc, argv, envp)`.
      # ... for `ENV`, we can probably call `getenv`, maybe `environ`.
      # Look into run_function_as_main(engine, fn, argc, argv, envp)
      private def generate_top_function(mod, scope = Stone::Scope.top_level)
        @top_function.generate(mod, scope)
      end
    end
  end
end
