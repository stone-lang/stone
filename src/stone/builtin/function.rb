module Stone

  module Builtin

    class Function < Object

      attr_reader :name
      attr_reader :arity
      attr_reader :proc

      def initialize(name, arity, proc)
        @name = name
        @arity = arity
        @proc = proc
      end

      def klass
        "Function"
      end

      def call(parent_context, arguments)
        proc.call(parent_context, arguments)
      end

      def to_s
        "Function(name: #{name}, arity: #{arity})"
      end

    end

  end

end
