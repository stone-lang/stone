require "stone"


RSpec.describe "Records" do

  describe "defining a record type" do
    it "allows a record type to be defined with typed fields" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        Person
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "allows a record type with a single field" do
      code = <<~STONE
        Wrapper := Record(value :: Int)
        Wrapper
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "allows a record type with multiple fields of the same type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "instantiating a record" do
    it "creates a record instance with provided values" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p := Person("Craig", 54)
        p
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "creates a record with a single field" do
      code = <<~STONE
        Wrapper := Record(value :: Int)
        w := Wrapper(42)
        w
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "accessing record fields" do
    it "allows accessing a string field" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p := Person("Craig", 54)
        p.name
      STONE
      expect(Stone.eval(code)).to eq("Craig")
    end

    it "allows accessing an integer field" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p := Person("Craig", 54)
        p.age
      STONE
      expect(Stone.eval(code)).to eq(54)
    end

    it "allows accessing fields from a record with multiple fields of same type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        pt := Point(10, 20)
        pt.x
      STONE
      expect(Stone.eval(code)).to eq(10)
    end

    it "allows accessing the second field of same type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        pt := Point(10, 20)
        pt.y
      STONE
      expect(Stone.eval(code)).to eq(20)
    end

    it "allows accessing fields from nested expressions" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        Person("Alice", 30).name
      STONE
      expect(Stone.eval(code)).to eq("Alice")
    end
  end

  describe "record equality" do
    it "returns TRUE when records have same type and values (integers only)" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p1 := Point(10, 20)
        p2 := Point(10, 20)
        ==(p1, p2)
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns FALSE when records have different values (integers only)" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p1 := Point(10, 20)
        p2 := Point(15, 25)
        ==(p1, p2)
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns FALSE when one field differs (integers only)" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p1 := Point(10, 20)
        p2 := Point(10, 25)
        ==(p1, p2)
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "works with chained comparison syntax (integers only)" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p1 := Point(10, 20)
        p2 := Point(10, 20)
        p1 == p2
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns TRUE when records have same type and values (with strings)" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p1 := Person("Craig", 54)
        p2 := Person("Craig", 54)
        ==(p1, p2)
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "returns FALSE when string fields differ" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)

        p1 := Person("Craig", 54)
        p2 := Person("Alice", 54)
        ==(p1, p2)
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "works with chained comparison syntax (with strings)" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p1 := Person("Craig", 54)
        p2 := Person("Craig", 54)
        p1 == p2
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "type checking" do
    it "raises an error when instantiating with wrong number of fields" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        Person("Craig")
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::ArgumentError, /wrong number of arguments/)
    end

    it "raises an error when instantiating with too many fields" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        Person("Craig", 54, "extra")
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::ArgumentError, /wrong number of arguments/)
    end

    it "raises an error when accessing a non-existent field" do
      code = <<~STONE
        Person := Record(name :: String, age :: Int)
        p := Person("Craig", 54)
        p.invalid_field
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::PropertyError, /Property.*not found/)
    end
  end

  describe "records with all integer fields" do
    it "creates and accesses a record with multiple int fields" do
      code = <<~STONE
        Point3D := Record(x :: Int, y :: Int, z :: Int)
        pt := Point3D(1, 2, 3)
        pt.z
      STONE
      expect(Stone.eval(code)).to eq(3)
    end
  end

  describe "records with all string fields" do
    it "creates and accesses a record with multiple string fields" do
      code = <<~STONE
        FullName := Record(first :: String, last :: String)
        name := FullName("Craig", "Buchek")
        name.last
      STONE
      expect(Stone.eval(code)).to eq("Buchek")
    end
  end

end
