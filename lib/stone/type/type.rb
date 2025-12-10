require "llvm/core"
require "stone/type/base"


module Stone
  module Type
    class Type < Base

      PROPERTY_TYPES = {}

      def self.name
        "Type"
      end

      def self.llvm_type
        # Types are represented as i64 for now (simple encoding)
        LLVM::Int64.type
      end

    end
  end
end
