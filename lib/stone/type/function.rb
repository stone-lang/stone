module Stone
  class Type
    class Function < Type

      def initialize(name:, param_types:, return_type:)
        super(name:, llvm_type: nil, param_types:, return_type:)
      end

      def function?
        true
      end

    end
  end
end
