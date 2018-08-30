module Stone

  module AST

    class Comment < Base

      attr_reader :text

      def initialize(text)
        @text = text
      end

      def type
        nil
      end

      def to_s
        text
      end

      def evaluate
        nil
      end

    end

  end

end
