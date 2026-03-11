require "stone/ast/type_declaration"
require "stone/type_registry"

module Stone
  class AST
    # Mixin for AST nodes that process statements in two phases:
    # 1. Register all type declarations in scope
    # 2. Compile other statements
    #
    # This ensures type declarations are available before definitions that reference them.
    module TwoPhaseProcessing

      # Register simple type declarations (non-function types).
      # These don't reference user-defined types and can be processed early.
      private def register_type_declarations(scope)
        registry = Stone::TypeRegistry.instance
        simple_type_declarations.each do |td|
          stone_type = td.type_annotation.to_type(registry)
          scope.declare_type(td.identifier, type: stone_type, location: td.location)
        end
      end

      # Register function type declarations that may reference user-defined types.
      # Called after record types are registered so references can be resolved.
      private def register_function_type_declarations(scope)
        registry = Stone::TypeRegistry.instance
        function_type_declarations.each do |td|
          stone_type = td.type_annotation.to_type(registry)
          scope.declare_type(td.identifier, type: stone_type, location: td.location)
        end
      end

      private def type_declarations
        all_statements.select { |s| s.is_a?(Stone::AST::TypeDeclaration) }
      end

      # Type declarations with function type annotations (may reference user types)
      private def function_type_declarations
        type_declarations.select { |td| td.type_annotation.is_a?(Stone::AST::FunctionTypeAnnotation) }
      end

      # Type declarations with non-function type annotations (simple types)
      private def simple_type_declarations
        type_declarations.reject { |td| td.type_annotation.is_a?(Stone::AST::FunctionTypeAnnotation) }
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
