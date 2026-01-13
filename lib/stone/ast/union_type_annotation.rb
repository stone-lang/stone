require "stone/ast"


module Stone
  class AST
    class UnionTypeAnnotation < Stone::AST

      attr_reader :alternatives

      def initialize(alternatives)
        @alternatives = alternatives
        @name = :union_type_annotation
      end

      def to_s
        @alternatives.map(&:to_s).join(" | ")
      end

      def to_type(registry)
        alternative_types = @alternatives.map { |t| t.to_type(registry) }.compact
        Stone::Type.union(alternatives: alternative_types)
      end

    end
  end
end
