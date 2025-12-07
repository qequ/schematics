require "./spec_helper"

describe "Schematics::Schema" do
  describe "basic types" do
    it "validates String" do
      schema = Schematics::Schema(String).new
      result = schema.validate("hello")
      result.valid?.should eq(true)

      result = schema.validate(123)
      result.valid?.should eq(false)
      result.errors.size.should eq(1)
      result.errors.first.error_message.should contain("expected type String")
    end

    it "validates Int32" do
      schema = Schematics::Schema(Int32).new
      result = schema.validate(42)
      result.valid?.should eq(true)

      result = schema.validate("42")
      result.valid?.should eq(false)
    end

    it "validates Float64" do
      schema = Schematics::Schema(Float64).new
      result = schema.validate(3.14)
      result.valid?.should eq(true)

      result = schema.validate(42)
      result.valid?.should eq(false)
    end

    it "validates Bool" do
      schema = Schematics::Schema(Bool).new
      schema.validate(true).valid?.should eq(true)
      schema.validate(false).valid?.should eq(true)
      schema.validate(1).valid?.should eq(false)
    end
  end

  describe "array types" do
    it "validates Array(Int32)" do
      schema = Schematics::Schema(Array(Int32)).new
      schema.validate([1, 2, 3]).valid?.should eq(true)
      schema.validate([1, 2, 3, 4, 5]).valid?.should eq(true)

      result = schema.validate([1, 2, "three"])
      result.valid?.should eq(false)
      result.errors.first.path.should contain("[2]")
    end

    it "validates Array(String)" do
      schema = Schematics::Schema(Array(String)).new
      schema.validate(["a", "b", "c"]).valid?.should eq(true)
      schema.validate(["a", 1, "c"]).valid?.should eq(false)
    end

    it "validates nested arrays" do
      schema = Schematics::Schema(Array(Array(Int32))).new
      schema.validate([[1, 2], [3, 4]]).valid?.should eq(true)
      schema.validate([[1, 2], [3, "4"]]).valid?.should eq(false)
    end
  end

  describe "hash types" do
    it "validates Hash(String, Int32)" do
      schema = Schematics::Schema(Hash(String, Int32)).new
      schema.validate({"a" => 1, "b" => 2}).valid?.should eq(true)
      schema.validate({"a" => 1, "b" => "2"}).valid?.should eq(false)
    end

    it "validates Hash(String, String)" do
      schema = Schematics::Schema(Hash(String, String)).new
      schema.validate({"name" => "John", "email" => "john@example.com"}).valid?.should eq(true)
      schema.validate({"name" => "John", "age" => 30}).valid?.should eq(false)
    end

    it "validates nested hashes" do
      schema = Schematics::Schema(Hash(String, Hash(String, Int32))).new
      schema.validate({"a" => {"x" => 1}, "b" => {"y" => 2}}).valid?.should eq(true)
      schema.validate({"a" => {"x" => 1}, "b" => {"y" => "2"}}).valid?.should eq(false)
    end
  end

  describe "error reporting" do
    it "provides detailed error messages" do
      schema = Schematics::Schema(Array(Int32)).new
      result = schema.validate([1, 2, "three", 4, "five"])

      result.valid?.should eq(false)
      result.errors.size.should eq(2)
      result.errors[0].path.should eq("root[2]")
      result.errors[1].path.should eq("root[4]")
    end

    it "reports nested errors" do
      schema = Schematics::Schema(Hash(String, Array(Int32))).new
      result = schema.validate({"numbers" => [1, 2, "three"]})

      result.valid?.should eq(false)
      result.errors.size.should eq(1)
      result.errors.first.path.should contain("numbers")
      # Note: Crystal's type system detects the mixed array type at the hash value level,
      # so the error is reported for the entire array, not the specific element
    end
  end

  describe "SchemaBuilder" do
    it "builds schema with min_size for arrays" do
      schema = Schematics::SchemaBuilder(Array(Int32)).new
        .min_size(2)
        .build

      schema.validate([1, 2, 3]).valid?.should eq(true)
      schema.validate([1]).valid?.should eq(false)
    end

    it "builds schema with max_size for arrays" do
      schema = Schematics::SchemaBuilder(Array(Int32)).new
        .max_size(3)
        .build

      schema.validate([1, 2]).valid?.should eq(true)
      schema.validate([1, 2, 3, 4]).valid?.should eq(false)
    end

    it "builds schema with min_length for strings" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(5)
        .build

      schema.validate("hello").valid?.should eq(true)
      schema.validate("hi").valid?.should eq(false)
    end

    it "builds schema with max_length for strings" do
      schema = Schematics::SchemaBuilder(String).new
        .max_length(10)
        .build

      schema.validate("short").valid?.should eq(true)
      schema.validate("this is way too long").valid?.should eq(false)
    end

    it "builds schema with min_value for numbers" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(18)
        .build

      schema.validate(20).valid?.should eq(true)
      schema.validate(15).valid?.should eq(false)
    end

    it "builds schema with max_value for numbers" do
      schema = Schematics::SchemaBuilder(Int32).new
        .max_value(100)
        .build

      schema.validate(50).valid?.should eq(true)
      schema.validate(150).valid?.should eq(false)
    end

    it "builds schema with custom validators" do
      schema = Schematics::SchemaBuilder(String).new
        .add_validator("must contain @") { |s| s.includes?("@") }
        .build

      schema.validate("user@example.com").valid?.should eq(true)
      schema.validate("invalid-email").valid?.should eq(false)
    end

    it "chains multiple validators" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(10)
        .max_value(100)
        .add_validator("must be even") { |n| n.even? }
        .build

      schema.validate(50).valid?.should eq(true)
      schema.validate(51).valid?.should eq(false)
      schema.validate(5).valid?.should eq(false)
      schema.validate(150).valid?.should eq(false)
    end
  end

  describe "parse method" do
    it "parses valid data" do
      schema = Schematics::Schema(Int32).new
      value = schema.parse(42)
      value.should eq(42)
    end

    it "raises on invalid data" do
      schema = Schematics::Schema(Int32).new
      expect_raises(Schematics::ValidationError) do
        schema.parse("not a number")
      end
    end

    it "parses arrays" do
      schema = Schematics::Schema(Array(String)).new
      value = schema.parse(["a", "b", "c"])
      value.should eq(["a", "b", "c"])
    end

    it "parses hashes" do
      schema = Schematics::Schema(Hash(String, Int32)).new
      value = schema.parse({"a" => 1, "b" => 2})
      value.should eq({"a" => 1, "b" => 2})
    end
  end

  describe "valid? method" do
    it "returns boolean for backward compatibility" do
      schema = Schematics::Schema(String).new
      schema.valid?("hello").should eq(true)
      schema.valid?(123).should eq(false)
    end
  end
end
