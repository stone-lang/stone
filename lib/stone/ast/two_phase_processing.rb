require "stone/ast/type_declaration"

module Stone
  class AST
    # Mixin for AST nodes that process statements in two phases:
    # 1. Register all type declarations in scope
    # 2. Compile other statements
    #
    # This ensures type declarations are available before definitions that reference them.
    module TwoPhaseProcessing

      private def register_type_declarations(scope)
        type_declarations.each do |td|
          scope.declare_type(td.identifier, type_annotation: td.type_annotation.to_s, location: td.location)
        end
      end

      private def type_declarations
        all_statements.select { |s| s.is_a?(Stone::AST::TypeDeclaration) }
      end

      private def other_statements
        all_statements.reject { |s| s.is_a?(Stone::AST::TypeDeclaration) }
      end

      # Subclasses must implement this method to return the list of statements to process
      private def all_statements
        fail NotImplementedError, "Subclasses must implement #all_statements"
      end

    end
  end
end
