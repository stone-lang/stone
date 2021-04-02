module Stone

  module AST

    class Comment < Node

      attr_reader :text

      def initialize(comment_text_slice)
        @source_location = comment_text_slice.line_and_column
        @text = comment_text_slice.to_s
      end

      def type
        nil
      end

      def to_s
        text
      end

      def evaluate(_context)
        nil
      end

    end

  end

end
