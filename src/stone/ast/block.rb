require "stone/context"

module Stone
  module AST
    class Block < Node

      attr_reader :body

      def initialize(body)
        @source_location = get_source_location(body)
        @body = body
      end

      def evaluate(_context)
        self
      end

      def call(parent_context)
        context = Context.new(parent_context)
        body.filter_map{ |x| x.evaluate(context) }.last
      end

      def to_s
        "{\n    #{body}\n}"
      end

    end
  end
end
