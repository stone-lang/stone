require "stone"


RSpec.describe "Recursive Record Types" do

  describe "defining recursive types" do
    it "can define a recursive record type" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        IntList
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "can define a tree type with multiple self-references" do
      code = <<~STONE
        Tree := Record(value :: Int, left :: Tree, right :: Tree)
        Tree
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "instantiating recursive types" do
    it "can create a single-element list with NULL terminator" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(42, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can create a multi-element list" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "can create a tree with NULL children" do
      code = <<~STONE
        Tree := Record(value :: Int, left :: Tree, right :: Tree)
        tree := Tree(42, NULL, NULL)
        tree.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "accessing recursive fields" do
    it "can access the rest field (returns pointer)" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq(2)
    end

    it "can access deeply nested elements" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    it "can check if rest is NULL" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(42, NULL)
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "can check if rest is not NULL" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, NULL))
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be false
    end
  end

  describe "string lists" do
    it "can create a list of strings" do
      code = <<~STONE
        StringList := Record(first :: String, rest :: StringList)
        list := StringList("hello", NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end

    it "can access nested string elements" do
      code = <<~STONE
        StringList := Record(first :: String, rest :: StringList)
        list := StringList("hello", StringList("world", NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq("world")
    end
  end

end
