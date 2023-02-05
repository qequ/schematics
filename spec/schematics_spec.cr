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
    schema.validate([1,2,3]).should eq(true)

    schema = Schema.new(Array(Int32))
    schema.validate([1,2,3.0]).should eq(false)

    schema = Schema.new(Array(Int32))
    schema.validate([1,2,"Hello"]).should eq(false)

    schema = Schema.new(Array(Int32))
    schema.validate([1,2,nil]).should eq(false)

    schema = Schema.new(Array(Float64))
    schema.validate([1.0,2.0,3.0]).should eq(true)

    schema = Schema.new(Array(Bool))
    schema.validate([true,false,true]).should eq(true)

    schema = Schema.new(Array(Bool))
    schema.validate([true,false,1]).should eq(false)

    schema = Schema.new(Array(Bool))
    schema.validate([true,false,"Hello"]).should eq(false)

    schema = Schema.new(Array(Bool))
    schema.validate([true,false,nil]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1,2.0,true]).should eq(true)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1,2.0,1]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1,2.0,"Hello"]).should eq(false)

    schema = Schema.new([Int32, Float64, Bool])
    schema.validate([1,2.0,nil]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1,2,3],[4,5,6]]).should eq(true)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1,2,3],[4,5,6.0]]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1,2,3],[4,5,"Hello"]]).should eq(false)

    schema = Schema.new(Array(Array(Int32)))
    schema.validate([[1,2,3],[4,5,nil]]).should eq(false)

    schema = Schema.new([Array(Int32),Int32])
    schema.validate([[1,2,3],4]).should eq(true)

    schema = Schema.new([Array(Int32),Int32])
    schema.validate([[1,2,3],4.0]).should eq(false)

    schema = Schema.new([[String, String], Int32, [Bool, Bool]])
    schema.validate([["Hello","World"], 1, [true,false]]).should eq(true)

    schema = Schema.new([[String, String], Int32, [Bool, Bool]])
    schema.validate([["Hello","World"], 1, [true]]).should eq(false)

  end
end
