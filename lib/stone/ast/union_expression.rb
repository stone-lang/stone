require "stone/ast/expression"


module Stone
  class AST
    class UnionExpression < Stone::AST::Expression

      attr_reader :alternatives
      attr_accessor :assigned_name

      def initialize(alternatives)
        @alternatives = alternatives
        @name = :union_expression
        @assigned_name = nil
      end

      def to_llir(_builder, _mod, _scope = Stone::Scope.top_level)
        # Union expressions define types, not runtime values.
        LLVM::Int64.from_i(0)
      end

      def substitute_type_params(substitution)
        new_alternatives = @alternatives.map { |alt| substitute_alternative(alt, substitution) }
        result = self.class.new(new_alternatives)
        result.assigned_name = @assigned_name
        result
      end

      def to_s
        @alternatives.map(&:to_s).join(" | ")
      end

      def type(_context = nil)
        nil
      end

      def record_alternatives
        @alternatives.select { |alt| alt.is_a?(Stone::AST::RecordDefinition) }
      end

      private def substitute_alternative(alt, substitution)
        case alt
        when Stone::AST::RecordDefinition
          alt.substitute_type_params(substitution)
        when Stone::AST::Reference
          substitute_reference(alt, substitution)
        else
          alt
        end
      end

      private def substitute_reference(ref, substitution)
        new_name = substitution[ref.identifier]
        new_name ? Stone::AST::Reference.new(new_name) : ref
      end

    end
  end
end
