module Stone
  class Type
    class Generic < Type

      attr_reader :template, :type_parameters, :record_template

      def initialize(name:, template:)
        @template = template
        @type_parameters = template.parameters
        @record_template = extract_record_template(template)
        super(name:, llvm_type: nil)
      end

      def generic?
        true
      end

      def specialize(type_arg_names)
        substitution = build_substitution(type_arg_names)
        specialized = record_template.substitute_type_params(substitution)
        specialized.assigned_name = canonical_name(type_arg_names)
        specialized
      end

      def canonical_name(type_arg_names)
        "#{name}(#{type_arg_names.join(', ')})"
      end

      private def build_substitution(type_arg_names)
        validate_arity!(type_arg_names)
        type_parameters.zip(type_arg_names).to_h
      end

      private def extract_record_template(template)
        record = template.block.statements.last
        fail ::ArgumentError, "generic type template must end with a RecordDefinition, got #{record.class}" unless record.is_a?(Stone::AST::RecordDefinition)

        record
      end

      private def validate_arity!(type_arg_names)
        return if type_arg_names.length == type_parameters.length

        fail Stone::TypeError,
             "wrong number of type arguments for #{name} (given #{type_arg_names.length}, expected #{type_parameters.length})"
      end

    end
  end
end
