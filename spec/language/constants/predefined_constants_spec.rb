require "stone"


RSpec.describe "Predefined Constants" do

  describe "ZERO" do
    it "evaluates to 0" do
      expect(Stone.eval("ZERO")).to eq(0)
    end
  end

  describe "ONE" do
    it "evaluates to 1" do
      expect(Stone.eval("ONE")).to eq(1)
    end
  end

  describe "undefined constants" do
    it "raise ReferenceError with the constant name" do
      expect { Stone.eval("MISSING") }.to raise_error(Stone::ReferenceError, /MISSING/)
    end
  end

end
