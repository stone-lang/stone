module Stone
  class Type
    class Record < Type
      class Field

        attr_reader :name, :type_annotation, :type_name

        def initialize(name:, type_annotation:, type_name: nil)
          @name = name
          @type_annotation = type_annotation
          @type_name = type_name || type_annotation&.to_s
        end

        def union_annotation?
          type_annotation.is_a?(Stone::AST::UnionTypeAnnotation)
        end

        def resolve_type(registry = Stone::Type::Registry)
          if type_annotation.respond_to?(:to_type)
            type_annotation.to_type(registry)
          else
            registry.lookup(type_name || type_annotation.to_s)
          end
        end

        def ==(other)
          other.is_a?(self.class) && other.name == name && other.type_name == type_name
        end
        alias eql? ==

        def hash
          [name, type_name].hash
        end

        def to_s
          "#{name} :: #{type_name}"
        end

        def inspect
          "#<Stone::Type::Record::Field #{self}>"
        end

      end
    end
  end
end
