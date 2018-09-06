module Stone

  module AST

    class Block < Base

      attr_reader :body

      def initialize(body)
        @source_location = get_source_location(body)
        @body = body
      end

      def evaluate(_context)
        self
      end

      def call
        context = {} # TODO: Need scopes for this to work right. Verify that we should start a new context here.
        body.map{ |x| x.evaluate(context) }.compact.last
      end

      def to_s
        "{\n    #{body}\n}"
      end

    end

  end

end
