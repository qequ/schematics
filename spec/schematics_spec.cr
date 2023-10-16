require "./spec_helper"

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
end
