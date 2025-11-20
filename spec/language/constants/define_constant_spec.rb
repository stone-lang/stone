require "stone"


RSpec.describe "Define Constant" do

  describe "defining a constant with a literal" do
    it "allows that constant to be referenced" do
      expect(Stone.eval("TWO := 2 ; TWO")).to eq(2)
    end
  end

end
