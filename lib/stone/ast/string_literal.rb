require "stone/ast/expression"
require "stone/type/String"


module Stone
  class AST
    class StringLiteral < Stone::AST::Expression

      def self.parse(text, location)
        # Remove surrounding quotes, but do NOT process escape sequences.
        value = text[1..-2]
        new(value)
      rescue ex
        raise Stone::Error.new(ex.message, location)
      end

      attr_reader :value

      def initialize(value)
        @name = :string_literal
        @value = value
      end

      # Byte count (for system/memory operations)
      def bytesize
        @value.bytesize
      end

      # Character count (for user-facing string length)
      def length
        @value.length
      end

      def to_llir(builder, mod)
        string_global = create_global_string(mod)

        # Get pointer to the string data (GEP to first element)
        # Array size is bytesize + 1 for null terminator
        string_ptr = builder.gep2(
          LLVM::Type.array(LLVM::Int8, @value.bytesize + 1),
          string_global,
          [LLVM::Int64.from_i(0), LLVM::Int64.from_i(0)],
          "string_ptr"
        )

        # Convert pointer to i64 so it can be returned via JIT
        # (FFI/JIT can't handle struct or pointer returns properly)
        builder.ptr2int(string_ptr, LLVM::Int64, "ptr_as_int")
      end

      private def create_global_string(mod)
        global_name = ".str.#{mod.globals.count}"
        string_constant = create_string_constant
        add_global_constant(mod, global_name, string_constant)
      end

      # Create string constant from bytes manually to work around ruby-llvm bugs:
      # 1. ConstantArray.string truncates Unicode strings
      # 2. ConstantArray.const with unsigned bytes > 127 produces poison values
      # Solution: convert bytes > 127 to signed i8 equivalent
      # Include null terminator for C string compatibility
      private def create_string_constant
        bytes_with_null = @value.bytes + [0]
        i8_constants = bytes_with_null.map { |byte| LLVM::Int8.from_i(byte > 127 ? byte - 256 : byte) }
        LLVM::ConstantArray.const(LLVM::Int8, i8_constants)
      end

      private def add_global_constant(mod, name, constant)
        mod.globals.add(constant.type, name).tap do |global|
          global.initializer = constant
          global.linkage = :private
          global.global_constant = true
          global.unnamed_addr = true
        end
      end

      def type(_context = nil)
        Stone::Type::String
      end

    end
  end
end
