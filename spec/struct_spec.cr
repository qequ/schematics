require "./spec_helper"

# Test struct definitions
struct TestPoint
  include Schematics::Struct

  field x, Float64, validators: [Schematics.gte(0.0)]
  field y, Float64, validators: [Schematics.gte(0.0)]
end

struct TestVector
  include Schematics::Struct

  field x, Float64
  field y, Float64
  field z, Float64
end

struct TestRectangle
  include Schematics::Struct

  field width, Float64, validators: [Schematics.gt(0.0)]
  field height, Float64, validators: [Schematics.gt(0.0)]

  protected def _collect_custom_errors(errs : Hash(Symbol, Array(String)))
    if width > height * 10
      errs[:width] ||= [] of String
      errs[:width] << "width cannot be more than 10x height"
    end
  end
end

struct TestConfig
  include Schematics::Struct

  field name, String, required: true, validators: [Schematics.min_length(1)]
  field port, Int32, default: 8080, validators: [Schematics.range(1, 65535)]
  field debug, Bool, default: false
end

struct TestOptionalStruct
  include Schematics::Struct

  field name, String
  field value, Int32?
  field description, String?, default: nil
end

struct TestRangeStruct
  include Schematics::Struct

  field temperature, Float64, validators: [Schematics.range(-273.15, 1000.0)]
  field percentage, Float64, validators: [Schematics.gte(0.0), Schematics.lte(100.0)]
end

describe Schematics::Struct do
  describe "field definitions" do
    it "creates struct with fields" do
      point = TestPoint.new(x: 10.0, y: 20.0)
      point.x.should eq(10.0)
      point.y.should eq(20.0)
    end

    it "creates struct with default values" do
      config = TestConfig.new(name: "app", port: 8080, debug: false)
      config.name.should eq("app")
      config.port.should eq(8080)
      config.debug.should be_false
    end

    it "supports nilable fields" do
      opt = TestOptionalStruct.new(name: "test", value: nil, description: nil)
      opt.name.should eq("test")
      opt.value.should be_nil
      opt.description.should be_nil
    end
  end

  describe "validation" do
    it "validates valid struct" do
      point = TestPoint.new(x: 10.0, y: 20.0)
      point.valid?.should be_true
      point.errors.should be_empty
    end

    it "validates invalid struct" do
      point = TestPoint.new(x: -5.0, y: 20.0)
      point.valid?.should be_false
      point.errors[:x].should_not be_empty
    end

    it "validates multiple fields" do
      point = TestPoint.new(x: -5.0, y: -10.0)
      point.valid?.should be_false
      point.errors[:x].should_not be_empty
      point.errors[:y].should_not be_empty
    end

    it "validates Float64 ranges" do
      range1 = TestRangeStruct.new(temperature: 25.0, percentage: 50.0)
      range1.valid?.should be_true

      range2 = TestRangeStruct.new(temperature: -300.0, percentage: 50.0)
      range2.valid?.should be_false
      range2.errors[:temperature].should_not be_empty

      range3 = TestRangeStruct.new(temperature: 25.0, percentage: 150.0)
      range3.valid?.should be_false
      range3.errors[:percentage].should_not be_empty
    end

    it "validates with gt/lt" do
      rect1 = TestRectangle.new(width: 10.0, height: 5.0)
      rect1.valid?.should be_true

      rect2 = TestRectangle.new(width: 0.0, height: 5.0)
      rect2.valid?.should be_false
      rect2.errors[:width].should_not be_empty
    end

    it "supports custom validation" do
      rect1 = TestRectangle.new(width: 50.0, height: 10.0)
      rect1.valid?.should be_true

      rect2 = TestRectangle.new(width: 150.0, height: 10.0)
      rect2.valid?.should be_false
      rect2.errors[:width].should contain("width cannot be more than 10x height")
    end

    it "validates required fields" do
      config = TestConfig.new(name: "", port: 8080, debug: false)
      config.valid?.should be_false
      config.errors[:name].should_not be_empty
    end

    it "validates Int32 range" do
      config1 = TestConfig.new(name: "app", port: 8080, debug: false)
      config1.valid?.should be_true

      config2 = TestConfig.new(name: "app", port: 0, debug: false)
      config2.valid?.should be_false
      config2.errors[:port].should_not be_empty

      config3 = TestConfig.new(name: "app", port: 70000, debug: false)
      config3.valid?.should be_false
      config3.errors[:port].should_not be_empty
    end
  end

  describe "validate!" do
    it "returns true for valid struct" do
      point = TestPoint.new(x: 10.0, y: 20.0)
      point.validate!.should be_true
    end

    it "raises for invalid struct" do
      point = TestPoint.new(x: -5.0, y: 20.0)
      expect_raises(Schematics::ValidationError) do
        point.validate!
      end
    end
  end

  describe "immutability" do
    it "has getter-only fields" do
      point = TestPoint.new(x: 10.0, y: 20.0)
      # This should compile - read-only access
      x_val : Float64 = point.x
      y_val : Float64 = point.y
      x_val.should eq(10.0)
      y_val.should eq(20.0)
    end

    it "returns fresh errors hash each time" do
      point = TestPoint.new(x: -5.0, y: 20.0)
      errors1 = point.errors
      errors2 = point.errors
      # Each call returns a new hash (non-mutating)
      errors1.should_not be(errors2)
      errors1.should eq(errors2)
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON" do
      point = TestPoint.new(x: 10.5, y: 20.5)
      json = point.to_json
      json.should contain("10.5")
      json.should contain("20.5")
    end

    it "deserializes from JSON" do
      json = %({"x": 15.0, "y": 25.0})
      point = TestPoint.from_json(json)
      point.x.should eq(15.0)
      point.y.should eq(25.0)
    end

    it "round-trips through JSON" do
      original = TestVector.new(x: 1.5, y: 2.5, z: 3.5)
      json = original.to_json
      restored = TestVector.from_json(json)

      restored.x.should eq(original.x)
      restored.y.should eq(original.y)
      restored.z.should eq(original.z)
    end

    it "handles nilable fields in JSON" do
      opt = TestOptionalStruct.new(name: "test", value: nil, description: nil)
      json = opt.to_json
      json.should contain("test")

      restored = TestOptionalStruct.from_json(json)
      restored.name.should eq("test")
      restored.value.should be_nil
    end

    it "serializes struct with mixed types" do
      config = TestConfig.new(name: "myapp", port: 3000, debug: true)
      json = config.to_json
      json.should contain("myapp")
      json.should contain("3000")
      json.should contain("true")

      restored = TestConfig.from_json(json)
      restored.name.should eq("myapp")
      restored.port.should eq(3000)
      restored.debug.should be_true
    end
  end

  describe "type safety" do
    it "enforces field types" do
      point = TestPoint.new(x: 10.0, y: 20.0)

      x_var : Float64 = point.x
      y_var : Float64 = point.y

      x_var.should be_a(Float64)
      y_var.should be_a(Float64)
    end

    it "handles nilable types correctly" do
      opt = TestOptionalStruct.new(name: "test", value: 42, description: "desc")

      name_var : String = opt.name
      value_var : Int32? = opt.value
      desc_var : String? = opt.description

      name_var.should be_a(String)
      value_var.should eq(42)
      desc_var.should eq("desc")
    end
  end

  describe "value semantics" do
    it "copies on assignment" do
      point1 = TestPoint.new(x: 10.0, y: 20.0)
      point2 = point1

      # Both have same values
      point1.x.should eq(point2.x)
      point1.y.should eq(point2.y)
    end
  end
end
