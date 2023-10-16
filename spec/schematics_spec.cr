require "./spec_helper"

# Define a simple struct for testing
struct Person
  property name : String
  property age : Int32

  def initialize(@name : String, @age : Int32)
  end
end

describe Schematics do
  it "ShouldvalidateBasicData" do
    schema = Schema.new(String)
    schema.validate("Hello").should eq(true)

    schema = Schema.new(Int32)
    schema.validate(1).should eq(true)

    schema = Schema.new(Int32)
    schema.validate(1.0).should eq(false)

    schema = Schema.new(Int32)
    schema.validate("Hello").should eq(false)

    schema = Schema.new(Int32)
    schema.validate(nil).should eq(false)

    schema = Schema.new(Float64)
    schema.validate(1.0).should eq(true)

    schema = Schema.new(Bool)
    schema.validate(true).should eq(true)

    schema = Schema.new(Bool)
    schema.validate(false).should eq(true)

    schema = Schema.new(Bool)
    schema.validate(nil).should eq(false)

    schema = Schema.new(Bool)
    schema.validate(1).should eq(false)

    schema = Schema.new(Bool)
    schema.validate("Hello").should eq(false)
  end

  it "ShouldValidateArrayData" do
    schema = Schema.new(Array(Int32))
    schema.validate([1, 2, 3]).should eq(true)

    schema = Schema.new(Array(Int32))
    schema.validate([1, 2, 3.0]).should eq(false)

    schema = Schema.new(Array(Int32))
    schema.validate([1, 2, "Hello"]).should eq(false)

    schema = Schema.new(Array(Int32))
    schema.validate([1, 2, nil]).should eq(false)

    schema = Schema.new(Array(Float64))
    schema.validate([1.0, 2.0, 3.0]).should eq(true)

    schema = Schema.new(Array(Bool))
    schema.validate([true, false, true]).should eq(true)

    schema = Schema.new(Array(Bool))
    schema.validate([true, false, 1]).should eq(false)

    schema = Schema.new(Array(Bool))
    schema.validate([true, false, "Hello"]).should eq(false)

    schema = Schema.new(Array(Bool))
    schema.validate([true, false, nil]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1, 2.0, true]).should eq(true)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1, 2.0, 1]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1, 2.0, "Hello"]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1, 2.0, nil]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1, 2, 3], [4, 5, 6]]).should eq(true)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1, 2, 3], [4, 5, 6.0]]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1, 2, 3], [4, 5, "Hello"]]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1, 2, 3], [4, 5, nil]]).should eq(false)

    schema = Schema.new([Array(Int32), Int32])
    schema.validate([[1, 2, 3], 4]).should eq(true)

    schema = Schema.new([Array(Int32), Int32])
    schema.validate([[1, 2, 3], 4.0]).should eq(false)

    schema = Schema.new([[String, String], Int32, [Bool, Bool]])
    schema.validate([["Hello", "World"], 1, [true, false]]).should eq(true)

    schema = Schema.new([[String, String], Int32, [Bool, Bool]])
    schema.validate([["Hello", "World"], 1, [true]]).should eq(false)
  end

  it "ShouldValidateHashData" do
    # Test with basic types
    schema = Schema.new(Hash(String, Int32))
    schema.validate({"a" => 1, "b" => 2}).should eq(true)
    schema.validate({"a" => 1, "b" => 2.0}).should eq(false)
    schema.validate({"a" => 1, "b" => "Hello"}).should eq(false)
    schema.validate({"a" => 1, "b" => nil}).should eq(false)

    # Test with nested hashes
    schema = Schema.new(Hash(String, Hash(String, Int32)))
    schema.validate({"a" => {"b" => 1}, "c" => {"d" => 2}}).should eq(true)
    schema.validate({"a" => {"b" => 1.0}, "c" => {"d" => 2}}).should eq(false)
    schema.validate({"a" => {"b" => "Hello"}, "c" => {"d" => 2}}).should eq(false)
    schema.validate({"a" => {"b" => nil}, "c" => {"d" => 2}}).should eq(false)

    # Test with mixed types
    schema = Schema.new(Hash(String, Array(Int32)))
    schema.validate({"a" => [1, 2, 3], "b" => [4, 5, 6]}).should eq(true)
    schema.validate({"a" => [1, 2, 3.0], "b" => [4, 5, 6]}).should eq(false)
    schema.validate({"a" => [1, 2, "Hello"], "b" => [4, 5, 6]}).should eq(false)
    schema.validate({"a" => [1, 2, nil], "b" => [4, 5, 6]}).should eq(false)

    # Test with different keys
    schema = Schema.new(Hash(String, Int32))
    schema.validate({"a" => 1, 1 => 2}).should eq(false)

    # Test with nested mixed types
    schema = Schema.new(Hash(String, Hash(String, Array(Int32))))
    schema.validate({"a" => {"b" => [1, 2, 3]}, "c" => {"d" => [4, 5, 6]}}).should eq(true)
    schema.validate({"a" => {"b" => [1, 2, 3.0]}, "c" => {"d" => [4, 5, 6]}}).should eq(false)
    schema.validate({"a" => {"b" => [1, 2, "Hello"]}, "c" => {"d" => [4, 5, 6]}}).should eq(false)
    schema.validate({"a" => {"b" => [1, 2, nil]}, "c" => {"d" => [4, 5, 6]}}).should eq(false)
  end

  describe "Schema with Structs" do
    it "validates struct data correctly" do
      # Create an instance of the struct
      person_instance = Person.new(name: "John", age: 30)

      # Create a schema using the struct type
      schema = Schema.new(Person)

      # Validate the instance against the schema
      schema.validate(person_instance).should eq(true)

      # Test with incorrect data type
      schema.validate("Not a Person struct").should eq(false)
    end
  end

  describe "Schema with Mixed Structs" do
    it "validates arrays containing structs correctly" do
      # Create an array of Person structs
      people_array = [Person.new(name: "John", age: 30), Person.new(name: "Jane", age: 25)]

      # Create a schema using an array of Person structs
      schema = Schema.new(Array(Person))

      # Validate the array against the schema
      schema.validate(people_array).should eq(true)

      # Test with an array containing incorrect data type
      incorrect_array = [Person.new(name: "John", age: 30), "Not a Person struct"]
      schema.validate(incorrect_array).should eq(false)
    end

    it "validates hashes with structs correctly" do
      # Create a hash with Person structs as values
      people_hash = {"John" => Person.new(name: "John", age: 30), "Jane" => Person.new(name: "Jane", age: 25)}

      # Create a schema using a hash with Person structs as values
      schema = Schema.new(Hash(String, Person))

      # Validate the hash against the schema
      schema.validate(people_hash).should eq(true)

      # Test with a hash containing incorrect data type as value
      incorrect_hash = {"John" => Person.new(name: "John", age: 30), "Jane" => "Not a Person struct"}
      schema.validate(incorrect_hash).should eq(false)

      # Test with a hash containing incorrect data type as key
      incorrect_key_hash = {Person.new(name: "John", age: 30) => "John", "Jane" => Person.new(name: "Jane", age: 25)}
      schema.validate(incorrect_key_hash).should eq(false)
    end
  end
end
