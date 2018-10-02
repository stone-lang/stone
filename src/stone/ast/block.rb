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

      def call(parent_context)
        context = Hash.new{ |_h, k| parent_context[k] }
        body.map{ |x| x.evaluate(context) }.compact.last
      end

      def to_s
        "{\n    #{body}\n}"
      end

      def recursively(&block)
        @body = body.map{ |stmt|
          stmt.recursively(block)
        }.compact
        block.call(self)
      end

    end

  end

end
