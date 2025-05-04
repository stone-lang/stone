module Stone

  module AST

    class PropertyAccess < Expression

      attr_accessor :subject
      attr_reader :property_name

      def initialize(subject, property_name)
        @subject = subject
        @property_name = property_name.to_sym
        @source_location = get_source_location(subject)
      end

      def evaluate(context)
        evaluated_subject = subject.evaluate(context)
        return evaluated_subject if error?(evaluated_subject)
        evaluated_subject.property(property_name)
      end

      def to_s
        "#{subject}.#{property_name}"
      end

    end

  end

end
