require "stone"


RSpec.describe "String Literals" do
  it "evaluates simple strings" do
    expect(Stone.eval('"hello"')).to eq("hello")
  end

  it "evaluates empty strings" do
    expect(Stone.eval('""')).to eq("")
  end

  it "handles hash character in strings (not a comment)" do
    expect(Stone.eval('"hello # world"')).to eq("hello # world")
  end

  it "handles strings with spaces" do
    expect(Stone.eval('"hello world"')).to eq("hello world")
  end

  it "handles strings with numbers" do
    expect(Stone.eval('"test123"')).to eq("test123")
  end

  it "handles strings with special characters" do
    expect(Stone.eval('"!@$%^&*()"')).to eq("!@$%^&*()")
  end

  it "handles strings with Unicode characters" do
    expect(Stone.eval('"hello λ world"')).to eq("hello λ world")
  end

  it "handles multi-word strings" do
    expect(Stone.eval('"The quick brown fox"')).to eq("The quick brown fox")
  end

  it "can be assigned to a constant" do
    expect(Stone.eval('GREETING := "hello"; GREETING')).to eq("hello")
  end
end
