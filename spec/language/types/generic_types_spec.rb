require "stone"


RSpec.describe "Generic Types" do

  describe "type-level lambda definitions" do
    it "allows defining a generic type as a type-level function" do
      code = <<~STONE
        Box :: (Type) -> Type
        Box := λ(T) { Record(value :: T) }
        Box
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "allows defining a generic type with two type parameters" do
      code = <<~STONE
        Pair :: (Type, Type) -> Type
        Pair := λ(KeyType, ValueType) { Record(key :: KeyType, value :: ValueType) }
        Pair
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

end
