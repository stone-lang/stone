require "stone/error/type_error"

module Stone
  class AST
    # Shared logic for registering union and record types in the Type::Registry.
    # Used by ConstantDefinition, FunctionCall, and TopFunction to avoid duplication.
    module UnionTypeRegistration

      private def register_placeholder_union(union_name)
        placeholder = Stone::Type.union(alternatives: [Stone::Type::Null], name: union_name)
        Stone::Type::Registry.register(placeholder)
      end

      private def resolve_alternative_type(alt)
        type = case alt
               when Stone::AST::RecordDefinition
                 Stone::Type::Registry.lookup(alt.assigned_name)
               when Stone::AST::Reference
                 Stone::Type::Registry.lookup(alt.identifier)
               else
                 fail Stone::TypeError, "Unsupported union alternative: #{alt.class}"
               end
        fail Stone::TypeError, "Unresolved union alternative: #{alt}" unless type

        type
      end

      private def register_record_type_in_registry(name, record_def, scope)
        # Register a placeholder type so self-referential union fields can resolve during llvm_type computation.
        placeholder = Stone::Type.record(name:, fields: record_def.fields, llvm_type: LLVM::Type.pointer)
        Stone::Type::Registry.register(placeholder)
        # Now compute the real llvm_type (union fields can resolve self-references via Registry).
        resolved = Stone::Type.record(name:, fields: record_def.fields, llvm_type: record_def.llvm_type(scope))
        Stone::Type::Registry.register(resolved)
        scope.declare_type(name, type: resolved) unless scope.type_declared_locally?(name)
      end

      private def register_union_in_registry(union_expr, union_name, scope, generic_base_name: nil)
        alternative_types = union_expr.alternatives.map { |alt| resolve_alternative_type(alt) }
        union_type = Stone::Type.union(alternatives: alternative_types, name: union_name, generic_base_name:)
        Stone::Type::Registry.register(union_type)
        scope.declare_type(union_name, type: union_type) unless scope.type_declared_locally?(union_name)
      end

      private def register_union_record_alternatives(union_expr, union_name, scope)
        register_placeholder_union(union_name)
        union_expr.record_alternatives.each_with_index do |record_def, index|
          record_name = "#{union_name}$#{index}"
          record_def.assigned_name = record_name
          register_record_type_in_registry(record_name, record_def, scope)
        end
      end

      private def extract_generic_base_name(name)
        paren_index = name.index("(")
        paren_index ? name[0...paren_index] : nil
      end

    end
  end
end
