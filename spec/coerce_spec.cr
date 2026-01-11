require "./spec_helper"

# Test model with coercion enabled
class CoercedUser < Schematics::Model
  field name, String, coerce: true
  field age, Int32, coerce: true
  field score, Float64, coerce: true
  field active, Bool, coerce: true
end

# Test model without coercion (strict mode)
class StrictUser < Schematics::Model
  field name, String
  field age, Int32
  field score, Float64
  field active, Bool
end

# Test model with mixed coercion
class MixedUser < Schematics::Model
  field name, String, coerce: true
  field age, Int32 # strict
  field score, Float64, coerce: true
  field active, Bool # strict
end

# Test model with nilable coerced fields
class CoercedOptionalUser < Schematics::Model
  field name, String, coerce: true
  field age, Int32?, coerce: true
  field score, Float64?, coerce: true
  field active, Bool?, coerce: true
end

# Test struct with coercion
struct CoercedPoint
  include Schematics::Struct

  field x, Float64, coerce: true
  field y, Float64, coerce: true
end

# Test struct without coercion
struct StrictPoint
  include Schematics::Struct

  field x, Float64
  field y, Float64
end

describe Schematics::Coerce do
  describe ".to_int32" do
    it "returns Int32 as-is" do
      Schematics::Coerce.to_int32(42).should eq(42)
    end

    it "converts Int64 within range" do
      Schematics::Coerce.to_int32(42_i64).should eq(42)
    end

    it "returns nil for Int64 out of range" do
      Schematics::Coerce.to_int32(Int64::MAX).should be_nil
    end

    it "converts Float64 whole numbers" do
      Schematics::Coerce.to_int32(42.0).should eq(42)
    end

    it "returns nil for Float64 with decimals" do
      Schematics::Coerce.to_int32(42.5).should be_nil
    end

    it "converts String with digits" do
      Schematics::Coerce.to_int32("42").should eq(42)
    end

    it "returns nil for non-numeric String" do
      Schematics::Coerce.to_int32("hello").should be_nil
    end

    it "converts Bool to 0/1" do
      Schematics::Coerce.to_int32(true).should eq(1)
      Schematics::Coerce.to_int32(false).should eq(0)
    end
  end

  describe ".to_int64" do
    it "returns Int64 as-is" do
      Schematics::Coerce.to_int64(42_i64).should eq(42_i64)
    end

    it "converts Int32" do
      Schematics::Coerce.to_int64(42).should eq(42_i64)
    end

    it "converts Float64 whole numbers" do
      Schematics::Coerce.to_int64(42.0).should eq(42_i64)
    end

    it "returns nil for Float64 with decimals" do
      Schematics::Coerce.to_int64(42.5).should be_nil
    end

    it "converts String with digits" do
      Schematics::Coerce.to_int64("42").should eq(42_i64)
    end

    it "converts Bool to 0/1" do
      Schematics::Coerce.to_int64(true).should eq(1_i64)
      Schematics::Coerce.to_int64(false).should eq(0_i64)
    end
  end

  describe ".to_float64" do
    it "returns Float64 as-is" do
      Schematics::Coerce.to_float64(3.14).should eq(3.14)
    end

    it "converts Int32" do
      Schematics::Coerce.to_float64(42).should eq(42.0)
    end

    it "converts Int64" do
      Schematics::Coerce.to_float64(42_i64).should eq(42.0)
    end

    it "converts String" do
      Schematics::Coerce.to_float64("3.14").should eq(3.14)
    end

    it "returns nil for non-numeric String" do
      Schematics::Coerce.to_float64("hello").should be_nil
    end
  end

  describe ".to_bool" do
    it "returns Bool as-is" do
      Schematics::Coerce.to_bool(true).should be_true
      Schematics::Coerce.to_bool(false).should be_false
    end

    it "converts Int 0/1" do
      Schematics::Coerce.to_bool(1).should be_true
      Schematics::Coerce.to_bool(0).should be_false
    end

    it "returns nil for other Int values" do
      Schematics::Coerce.to_bool(2).should be_nil
      Schematics::Coerce.to_bool(-1).should be_nil
    end

    it "converts true-like strings" do
      Schematics::Coerce.to_bool("true").should be_true
      Schematics::Coerce.to_bool("TRUE").should be_true
      Schematics::Coerce.to_bool("yes").should be_true
      Schematics::Coerce.to_bool("YES").should be_true
      Schematics::Coerce.to_bool("1").should be_true
      Schematics::Coerce.to_bool("on").should be_true
      Schematics::Coerce.to_bool("t").should be_true
      Schematics::Coerce.to_bool("y").should be_true
    end

    it "converts false-like strings" do
      Schematics::Coerce.to_bool("false").should be_false
      Schematics::Coerce.to_bool("FALSE").should be_false
      Schematics::Coerce.to_bool("no").should be_false
      Schematics::Coerce.to_bool("NO").should be_false
      Schematics::Coerce.to_bool("0").should be_false
      Schematics::Coerce.to_bool("off").should be_false
      Schematics::Coerce.to_bool("f").should be_false
      Schematics::Coerce.to_bool("n").should be_false
    end

    it "returns nil for unknown strings" do
      Schematics::Coerce.to_bool("hello").should be_nil
      Schematics::Coerce.to_bool("maybe").should be_nil
    end
  end

  describe ".to_string" do
    it "returns String as-is" do
      Schematics::Coerce.to_string("hello").should eq("hello")
    end

    it "converts Int32" do
      Schematics::Coerce.to_string(42).should eq("42")
    end

    it "converts Int64" do
      Schematics::Coerce.to_string(42_i64).should eq("42")
    end

    it "converts Float64" do
      Schematics::Coerce.to_string(3.14).should eq("3.14")
    end

    it "converts Bool" do
      Schematics::Coerce.to_string(true).should eq("true")
      Schematics::Coerce.to_string(false).should eq("false")
    end
  end
end

describe "Model with coercion" do
  describe "from_json with coerce: true" do
    it "coerces string to int" do
      json = %({
        "name": "John",
        "age": "25",
        "score": 85.5,
        "active": true
      })
      user = CoercedUser.from_json(json)
      user.age.should eq(25)
    end

    it "coerces int to string" do
      json = %({
        "name": 12345,
        "age": 25,
        "score": 85.5,
        "active": true
      })
      user = CoercedUser.from_json(json)
      user.name.should eq("12345")
    end

    it "coerces string to float" do
      json = %({
        "name": "John",
        "age": 25,
        "score": "85.5",
        "active": true
      })
      user = CoercedUser.from_json(json)
      user.score.should eq(85.5)
    end

    it "coerces int to float" do
      json = %({
        "name": "John",
        "age": 25,
        "score": 85,
        "active": true
      })
      user = CoercedUser.from_json(json)
      user.score.should eq(85.0)
    end

    it "coerces string to bool" do
      json = %({
        "name": "John",
        "age": 25,
        "score": 85.5,
        "active": "true"
      })
      user = CoercedUser.from_json(json)
      user.active.should be_true
    end

    it "coerces int to bool" do
      json = %({
        "name": "John",
        "age": 25,
        "score": 85.5,
        "active": 1
      })
      user = CoercedUser.from_json(json)
      user.active.should be_true
    end

    it "raises when coercion fails" do
      json = %({
        "name": "John",
        "age": "not a number",
        "score": 85.5,
        "active": true
      })
      expect_raises(Exception, /Failed to coerce.*Int32.*age/) do
        CoercedUser.from_json(json)
      end
    end
  end

  describe "from_json without coercion (strict)" do
    it "accepts correct types" do
      json = %({
        "name": "John",
        "age": 25,
        "score": 85.5,
        "active": true
      })
      user = StrictUser.from_json(json)
      user.name.should eq("John")
      user.age.should eq(25)
      user.score.should eq(85.5)
      user.active.should be_true
    end

    it "raises on type mismatch" do
      json = %({
        "name": "John",
        "age": "25",
        "score": 85.5,
        "active": true
      })
      expect_raises(Exception) do
        StrictUser.from_json(json)
      end
    end
  end

  describe "mixed coercion" do
    it "coerces only enabled fields" do
      json = %({
        "name": 12345,
        "age": 25,
        "score": "85.5",
        "active": true
      })
      user = MixedUser.from_json(json)
      user.name.should eq("12345") # coerced
      user.age.should eq(25)       # strict
      user.score.should eq(85.5)   # coerced
      user.active.should be_true   # strict
    end
  end

  describe "nilable fields with coercion" do
    it "coerces nilable fields" do
      json = %({
        "name": "John",
        "age": "25",
        "score": null,
        "active": "yes"
      })
      user = CoercedOptionalUser.from_json(json)
      user.name.should eq("John")
      user.age.should eq(25)
      user.score.should be_nil
      user.active.should be_true
    end

    it "returns nil when coercion fails for nilable field" do
      json = %({
        "name": "John",
        "age": "not a number",
        "score": null,
        "active": null
      })
      user = CoercedOptionalUser.from_json(json)
      user.age.should be_nil # failed coercion returns nil for nilable
    end
  end
end

describe "Struct with coercion" do
  describe "from_json with coerce: true" do
    it "coerces string to float" do
      json = %({
        "x": "10.5",
        "y": "20.5"
      })
      point = CoercedPoint.from_json(json)
      point.x.should eq(10.5)
      point.y.should eq(20.5)
    end

    it "coerces int to float" do
      json = %({
        "x": 10,
        "y": 20
      })
      point = CoercedPoint.from_json(json)
      point.x.should eq(10.0)
      point.y.should eq(20.0)
    end

    it "raises when coercion fails" do
      json = %({
        "x": "not a number",
        "y": 20
      })
      expect_raises(Exception, /Failed to coerce.*Float64.*x/) do
        CoercedPoint.from_json(json)
      end
    end
  end

  describe "from_json without coercion (strict)" do
    it "accepts correct types" do
      json = %({
        "x": 10.5,
        "y": 20.5
      })
      point = StrictPoint.from_json(json)
      point.x.should eq(10.5)
      point.y.should eq(20.5)
    end

    it "raises on type mismatch" do
      json = %({
        "x": "10.5",
        "y": 20.5
      })
      expect_raises(Exception) do
        StrictPoint.from_json(json)
      end
    end
  end
end

# Complex model with coercion AND validators
class CoercedValidatedUser < Schematics::Model
  field name, String, coerce: true, validators: [Schematics.min_length(2)]
  field age, Int32, coerce: true, validators: [Schematics.gte(0), Schematics.lte(150)]
  field score, Float64, coerce: true, validators: [Schematics.gte(0.0), Schematics.lte(100.0)]
  field active, Bool, coerce: true
  field role, String, coerce: true, validators: [Schematics.one_of(["admin", "user", "guest"])]
end

# Model to test falsy value edge cases (the bug we fixed)
class FalsyValuesModel < Schematics::Model
  field enabled, Bool, coerce: true
  field count, Int32, coerce: true
  field rate, Float64, coerce: true
  field label, String, coerce: true
end

# Struct with coercion and validators
struct CoercedValidatedPoint
  include Schematics::Struct

  field x, Float64, coerce: true, validators: [Schematics.gte(0.0)]
  field y, Float64, coerce: true, validators: [Schematics.gte(0.0)]
end

# Model with all nilable coerced fields and validators
class FullyOptionalCoerced < Schematics::Model
  field name, String?, coerce: true
  field count, Int32?, coerce: true, validators: [Schematics.gte(0)]
  field rate, Float64?, coerce: true
  field enabled, Bool?, coerce: true
end

describe "Coercion edge cases - falsy values" do
  describe "Bool coercion with false values" do
    it "correctly coerces JSON false to Bool false" do
      json = %({"enabled": false, "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end

    it "correctly coerces string 'false' to Bool false" do
      json = %({"enabled": "false", "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end

    it "correctly coerces string 'no' to Bool false" do
      json = %({"enabled": "no", "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end

    it "correctly coerces string '0' to Bool false" do
      json = %({"enabled": "0", "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end

    it "correctly coerces int 0 to Bool false" do
      json = %({"enabled": 0, "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end

    it "correctly coerces string 'off' to Bool false" do
      json = %({"enabled": "off", "count": 10, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.enabled.should be_false
    end
  end

  describe "Int32 coercion with zero" do
    it "correctly coerces JSON 0 to Int32 0" do
      json = %({"enabled": true, "count": 0, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.count.should eq(0)
    end

    it "correctly coerces string '0' to Int32 0" do
      json = %({"enabled": true, "count": "0", "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.count.should eq(0)
    end

    it "correctly coerces float 0.0 to Int32 0" do
      json = %({"enabled": true, "count": 0.0, "rate": 1.5, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.count.should eq(0)
    end
  end

  describe "Float64 coercion with zero" do
    it "correctly coerces JSON 0 to Float64 0.0" do
      json = %({"enabled": true, "count": 10, "rate": 0, "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.rate.should eq(0.0)
    end

    it "correctly coerces string '0' to Float64 0.0" do
      json = %({"enabled": true, "count": 10, "rate": "0", "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.rate.should eq(0.0)
    end

    it "correctly coerces string '0.0' to Float64 0.0" do
      json = %({"enabled": true, "count": 10, "rate": "0.0", "label": "test"})
      model = FalsyValuesModel.from_json(json)
      model.rate.should eq(0.0)
    end
  end

  describe "String coercion with empty string" do
    it "correctly handles empty string" do
      json = %({"enabled": true, "count": 10, "rate": 1.5, "label": ""})
      model = FalsyValuesModel.from_json(json)
      model.label.should eq("")
    end
  end
end

describe "Coercion with validators" do
  describe "Model with coercion and validation" do
    it "coerces and validates valid data" do
      json = %({
        "name": 12345,
        "age": "25",
        "score": "85",
        "active": "yes",
        "role": "admin"
      })
      user = CoercedValidatedUser.from_json(json)
      user.name.should eq("12345")
      user.age.should eq(25)
      user.score.should eq(85.0)
      user.active.should be_true
      user.role.should eq("admin")
      user.valid?.should be_true
    end

    it "coerces then fails validation" do
      json = %({
        "name": "A",
        "age": "25",
        "score": "85",
        "active": true,
        "role": "admin"
      })
      user = CoercedValidatedUser.from_json(json)
      user.name.should eq("A")
      user.valid?.should be_false
      user.errors[:name].should_not be_empty
    end

    it "validates age range after coercion" do
      json = %({
        "name": "John",
        "age": "200",
        "score": "85",
        "active": true,
        "role": "user"
      })
      user = CoercedValidatedUser.from_json(json)
      user.age.should eq(200)
      user.valid?.should be_false
      user.errors[:age].should_not be_empty
    end

    it "validates score range after coercion" do
      json = %({
        "name": "John",
        "age": "25",
        "score": "150",
        "active": true,
        "role": "user"
      })
      user = CoercedValidatedUser.from_json(json)
      user.score.should eq(150.0)
      user.valid?.should be_false
      user.errors[:score].should_not be_empty
    end

    it "validates one_of after coercion" do
      json = %({
        "name": "John",
        "age": "25",
        "score": "85",
        "active": true,
        "role": "superuser"
      })
      user = CoercedValidatedUser.from_json(json)
      user.role.should eq("superuser")
      user.valid?.should be_false
      user.errors[:role].should_not be_empty
    end

    it "multiple validation failures after coercion" do
      json = %({
        "name": "X",
        "age": "-5",
        "score": "200",
        "active": true,
        "role": "invalid"
      })
      user = CoercedValidatedUser.from_json(json)
      user.valid?.should be_false
      user.errors[:name].should_not be_empty
      user.errors[:age].should_not be_empty
      user.errors[:score].should_not be_empty
      user.errors[:role].should_not be_empty
    end
  end

  describe "Struct with coercion and validation" do
    it "coerces and validates valid data" do
      json = %({"x": "10", "y": "20"})
      point = CoercedValidatedPoint.from_json(json)
      point.x.should eq(10.0)
      point.y.should eq(20.0)
      point.valid?.should be_true
    end

    it "coerces then fails validation for negative values" do
      json = %({"x": "-5", "y": "20"})
      point = CoercedValidatedPoint.from_json(json)
      point.x.should eq(-5.0)
      point.valid?.should be_false
      point.errors[:x].should_not be_empty
    end

    it "validates zero correctly (boundary)" do
      json = %({"x": "0", "y": "0"})
      point = CoercedValidatedPoint.from_json(json)
      point.x.should eq(0.0)
      point.y.should eq(0.0)
      point.valid?.should be_true
    end
  end
end

describe "Nilable coerced fields with complex scenarios" do
  it "handles all nil values" do
    json = %({"name": null, "count": null, "rate": null, "enabled": null})
    model = FullyOptionalCoerced.from_json(json)
    model.name.should be_nil
    model.count.should be_nil
    model.rate.should be_nil
    model.enabled.should be_nil
    model.valid?.should be_true
  end

  it "handles mixed nil and coerced values" do
    json = %({"name": 123, "count": "42", "rate": null, "enabled": "yes"})
    model = FullyOptionalCoerced.from_json(json)
    model.name.should eq("123")
    model.count.should eq(42)
    model.rate.should be_nil
    model.enabled.should be_true
    model.valid?.should be_true
  end

  it "returns nil for failed coercion on nilable field" do
    json = %({"name": "test", "count": "not a number", "rate": "invalid", "enabled": "maybe"})
    model = FullyOptionalCoerced.from_json(json)
    model.name.should eq("test")
    model.count.should be_nil
    model.rate.should be_nil
    model.enabled.should be_nil
  end

  it "validates coerced nilable values" do
    json = %({"name": "test", "count": "-5", "rate": 1.5, "enabled": true})
    model = FullyOptionalCoerced.from_json(json)
    model.count.should eq(-5)
    model.valid?.should be_false
    model.errors[:count].should_not be_empty
  end

  it "skips validation for nil values on nilable fields" do
    json = %({"name": null, "count": null, "rate": null, "enabled": null})
    model = FullyOptionalCoerced.from_json(json)
    model.valid?.should be_true
    model.errors.should be_empty
  end
end

describe "Complex coercion scenarios" do
  it "handles negative numbers" do
    json = %({"enabled": true, "count": "-42", "rate": "-3.14", "label": "negative"})
    model = FalsyValuesModel.from_json(json)
    model.count.should eq(-42)
    model.rate.should eq(-3.14)
  end

  it "handles scientific notation for floats" do
    json = %({"enabled": true, "count": 100, "rate": "1.5e2", "label": "scientific"})
    model = FalsyValuesModel.from_json(json)
    model.rate.should eq(150.0)
  end

  it "handles large integers" do
    json = %({"enabled": true, "count": "2147483647", "rate": 1.0, "label": "max"})
    model = FalsyValuesModel.from_json(json)
    model.count.should eq(Int32::MAX)
  end

  it "handles bool to int coercion" do
    json = %({"enabled": true, "count": true, "rate": 1.0, "label": "bool"})
    model = FalsyValuesModel.from_json(json)
    model.count.should eq(1)
  end

  it "handles float to int coercion (whole number)" do
    json = %({"enabled": true, "count": 42.0, "rate": 1.0, "label": "float"})
    model = FalsyValuesModel.from_json(json)
    model.count.should eq(42)
  end

  it "fails float to int coercion (non-whole number)" do
    json = %({"enabled": true, "count": 42.5, "rate": 1.0, "label": "float"})
    expect_raises(Exception, /Failed to coerce.*Int32.*count/) do
      FalsyValuesModel.from_json(json)
    end
  end

  it "coerces int to string" do
    json = %({"enabled": true, "count": 42, "rate": 1.0, "label": 12345})
    model = FalsyValuesModel.from_json(json)
    model.label.should eq("12345")
  end

  it "coerces float to string" do
    json = %({"enabled": true, "count": 42, "rate": 1.0, "label": 3.14})
    model = FalsyValuesModel.from_json(json)
    model.label.should eq("3.14")
  end

  it "coerces bool to string" do
    json = %({"enabled": true, "count": 42, "rate": 1.0, "label": true})
    model = FalsyValuesModel.from_json(json)
    model.label.should eq("true")
  end
end
