require "stone/properties"

RSpec.describe Stone::PropertyRegistry do

  describe "registering built-in properties" do
    it "registers Bool.not property" do
      property = Stone::PropertyRegistry.lookup("Bool", "not")
      expect(property).not_to be_nil
    end

    it "registers Int.positive? property" do
      property = Stone::PropertyRegistry.lookup("Int", "positive?")
      expect(property).not_to be_nil
    end

    it "registers Int.negative? property" do
      property = Stone::PropertyRegistry.lookup("Int", "negative?")
      expect(property).not_to be_nil
    end

    it "registers Int.zero? property" do
      property = Stone::PropertyRegistry.lookup("Int", "zero?")
      expect(property).not_to be_nil
    end

    it "registers String.byte_count property" do
      property = Stone::PropertyRegistry.lookup("String", "byte_count")
      expect(property).not_to be_nil
    end
  end

  describe "looking up properties" do
    it "returns nil for unregistered property" do
      property = Stone::PropertyRegistry.lookup("Int", "nonexistent")
      expect(property).to be_nil
    end

    it "returns nil for unregistered type" do
      property = Stone::PropertyRegistry.lookup("FakeType", "anything")
      expect(property).to be_nil
    end
  end

  describe "property implementation" do
    it "returns a callable block for registered properties" do
      property = Stone::PropertyRegistry.lookup("Bool", "not")
      expect(property).to respond_to(:call)
    end
  end

end
