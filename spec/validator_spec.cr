require "./spec_helper"

describe "Schematics::Validators" do
  describe "TypeValidator" do
    it "validates basic types correctly" do
      validator = Schematics::TypeValidator(String).new
      result = validator.validate("hello", "root")
      result.valid?.should eq(true)

      result = validator.validate(123, "root")
      result.valid?.should eq(false)
    end

    it "provides correct path in errors" do
      validator = Schematics::TypeValidator(Int32).new
      result = validator.validate("wrong", "user.age")

      result.errors.first.path.should eq("user.age")
    end
  end

  describe "ArrayValidator" do
    it "validates empty arrays" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator)

      result = validator.validate([] of Int32, "root")
      result.valid?.should eq(true)
    end

    it "validates array with all valid elements" do
      element_validator = Schematics::TypeValidator(String).new
      validator = Schematics::ArrayValidator(String).new(element_validator)

      result = validator.validate(["a", "b", "c"], "root")
      result.valid?.should eq(true)
    end

    it "reports all invalid elements" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator)

      result = validator.validate([1, "two", 3, "four"], "numbers")
      result.valid?.should eq(false)
      result.errors.size.should eq(2)

      paths = result.errors.map(&.path)
      paths.should contain("numbers[1]")
      paths.should contain("numbers[3]")
    end

    it "enforces min_size constraint" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator, min_size: 3)

      validator.validate([1, 2], "root").valid?.should eq(false)
      validator.validate([1, 2, 3], "root").valid?.should eq(true)
      validator.validate([1, 2, 3, 4], "root").valid?.should eq(true)
    end

    it "enforces max_size constraint" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator, max_size: 3)

      validator.validate([1, 2], "root").valid?.should eq(true)
      validator.validate([1, 2, 3], "root").valid?.should eq(true)
      validator.validate([1, 2, 3, 4], "root").valid?.should eq(false)
    end

    it "enforces both min and max size" do
      element_validator = Schematics::TypeValidator(String).new
      validator = Schematics::ArrayValidator(String).new(element_validator, min_size: 2, max_size: 4)

      validator.validate(["a"], "root").valid?.should eq(false)
      validator.validate(["a", "b"], "root").valid?.should eq(true)
      validator.validate(["a", "b", "c"], "root").valid?.should eq(true)
      validator.validate(["a", "b", "c", "d"], "root").valid?.should eq(true)
      validator.validate(["a", "b", "c", "d", "e"], "root").valid?.should eq(false)
    end
  end

  describe "HashValidator" do
    it "validates empty hashes" do
      key_validator = Schematics::TypeValidator(String).new
      value_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::HashValidator(String, Int32).new(key_validator, value_validator)

      result = validator.validate({} of String => Int32, "root")
      result.valid?.should eq(true)
    end

    it "validates hash with correct types" do
      key_validator = Schematics::TypeValidator(String).new
      value_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::HashValidator(String, Int32).new(key_validator, value_validator)

      result = validator.validate({"a" => 1, "b" => 2}, "root")
      result.valid?.should eq(true)
    end

    it "reports invalid value types" do
      key_validator = Schematics::TypeValidator(String).new
      value_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::HashValidator(String, Int32).new(key_validator, value_validator)

      result = validator.validate({"a" => 1, "b" => "wrong"}, "data")
      result.valid?.should eq(false)
      result.errors.first.path.should contain("data[b]")
    end

    it "validates nested hash structures" do
      key_validator = Schematics::TypeValidator(String).new
      inner_key_validator = Schematics::TypeValidator(String).new
      inner_value_validator = Schematics::TypeValidator(Int32).new
      inner_hash_validator = Schematics::HashValidator(String, Int32).new(
        inner_key_validator,
        inner_value_validator
      )
      validator = Schematics::HashValidator(String, Hash(String, Int32)).new(
        key_validator,
        inner_hash_validator
      )

      valid_data = {"outer" => {"inner" => 42}}
      result = validator.validate(valid_data, "root")
      result.valid?.should eq(true)
    end
  end

  describe "CustomValidator" do
    it "validates with custom proc" do
      validator = Schematics::CustomValidator(Int32).new(
        ->(n : Int32) { n.even? },
        "must be even"
      )

      validator.validate(4, "root").valid?.should eq(true)
      validator.validate(5, "root").valid?.should eq(false)
    end

    it "provides custom error message" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) { s.starts_with?("test") },
        "must start with test"
      )

      result = validator.validate("hello", "field")
      result.valid?.should eq(false)
      result.errors.first.error_message.should contain("must start with test")
    end

    it "validates complex conditions" do
      # Validate that a number is prime
      is_prime = ->(n : Int32) {
        return false if n < 2
        return true if n == 2
        return false if n.even?
        (3..Math.sqrt(n).to_i).step(2).none? { |i| n % i == 0 }
      }

      validator = Schematics::CustomValidator(Int32).new(is_prime, "must be prime")

      validator.validate(2, "root").valid?.should eq(true)
      validator.validate(3, "root").valid?.should eq(true)
      validator.validate(5, "root").valid?.should eq(true)
      validator.validate(7, "root").valid?.should eq(true)
      validator.validate(4, "root").valid?.should eq(false)
      validator.validate(6, "root").valid?.should eq(false)
      validator.validate(9, "root").valid?.should eq(false)
    end
  end

  describe "ValidatorChain" do
    it "runs all validators in sequence" do
      validator1 = Schematics::TypeValidator(Int32).new
      validator2 = Schematics::CustomValidator(Int32).new(
        ->(n : Int32) { n > 0 },
        "must be positive"
      )
      validator3 = Schematics::CustomValidator(Int32).new(
        ->(n : Int32) { n < 100 },
        "must be less than 100"
      )

      validators = [validator1, validator2, validator3] of Schematics::Validator(Int32)
      chain = Schematics::ValidatorChain(Int32).new(validators)

      chain.validate(50, "root").valid?.should eq(true)
      chain.validate(-5, "root").valid?.should eq(false)
      chain.validate(150, "root").valid?.should eq(false)
    end

    it "collects all validation errors" do
      validator1 = Schematics::CustomValidator(String).new(
        ->(s : String) { s.size >= 5 },
        "too short"
      )
      validator2 = Schematics::CustomValidator(String).new(
        ->(s : String) { s.includes?("@") },
        "missing @"
      )

      validators = [validator1, validator2] of Schematics::Validator(String)
      chain = Schematics::ValidatorChain(String).new(validators)

      result = chain.validate("ab", "email")
      result.valid?.should eq(false)
      result.errors.size.should eq(2)
    end

    it "runs all validators even on type failure" do
      type_validator = Schematics::TypeValidator(Int32).new
      custom_validator = Schematics::CustomValidator(Int32).new(
        ->(n : Int32) { n > 0 },
        "must be positive"
      )

      validators = [type_validator, custom_validator] of Schematics::Validator(Int32)
      chain = Schematics::ValidatorChain(Int32).new(validators)

      # Both validators run, collecting all errors
      result = chain.validate("not a number", "root")
      result.valid?.should eq(false)
      result.errors.size.should eq(2) # Type error and custom validator error
    end
  end

  describe "validation with different paths" do
    it "constructs correct paths for nested structures" do
      schema = Schematics::Schema(Hash(String, Array(Int32))).new

      data = {
        "numbers" => [1, 2, "three"],
        "values"  => [4, 5, 6],
      }

      result = schema.validate(data)
      result.valid?.should eq(false)
      result.errors.first.path.should contain("numbers")
    end

    it "maintains path through multiple nesting levels" do
      schema = Schematics::Schema(Array(Hash(String, Int32))).new

      data = [
        {"a" => 1},
        {"b" => "wrong"},
      ]

      result = schema.validate(data)
      result.valid?.should eq(false)
    end
  end

  describe "validator call method" do
    it "returns parsed value on success" do
      validator = Schematics::TypeValidator(Int32).new
      result = validator.call(42)
      result.should eq(42)
    end

    it "returns nil on failure" do
      validator = Schematics::TypeValidator(Int32).new
      result = validator.call("not int")
      result.should eq(nil)
    end

    it "works with array validator" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator)

      result = validator.call([1, 2, 3])
      result.should eq([1, 2, 3])

      result = validator.call([1, "two"])
      result.should eq(nil)
    end

    it "works with hash validator" do
      key_validator = Schematics::TypeValidator(String).new
      value_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::HashValidator(String, Int32).new(key_validator, value_validator)

      result = validator.call({"a" => 1})
      result.should eq({"a" => 1})

      result = validator.call({"a" => "wrong"})
      result.should eq(nil)
    end
  end

  describe "real-world validation patterns" do
    it "validates email-like strings" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) {
          parts = s.split("@")
          parts.size == 2 && parts[1].includes?(".")
        },
        "invalid email format"
      )

      validator.validate("user@example.com", "root").valid?.should eq(true)
      validator.validate("user@localhost", "root").valid?.should eq(false)
      validator.validate("invalid", "root").valid?.should eq(false)
    end

    it "validates URL-like strings" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) {
          s.starts_with?("http://") || s.starts_with?("https://")
        },
        "must be a valid URL"
      )

      validator.validate("https://example.com", "root").valid?.should eq(true)
      validator.validate("http://example.com", "root").valid?.should eq(true)
      validator.validate("ftp://example.com", "root").valid?.should eq(false)
    end

    it "validates phone number format" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) { s.matches?(/^\d{3}-\d{3}-\d{4}$/) },
        "must be in format XXX-XXX-XXXX"
      )

      validator.validate("555-123-4567", "root").valid?.should eq(true)
      validator.validate("5551234567", "root").valid?.should eq(false)
      validator.validate("555-12-3456", "root").valid?.should eq(false)
    end

    it "validates credit card-like format" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) {
          digits = s.gsub(/\D/, "")
          digits.size >= 13 && digits.size <= 19
        },
        "invalid card number"
      )

      validator.validate("4532015112830366", "root").valid?.should eq(true)
      validator.validate("4532 0151 1283 0366", "root").valid?.should eq(true)
      validator.validate("1234", "root").valid?.should eq(false)
    end

    it "validates UUID format" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) {
          s.matches?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
        },
        "invalid UUID format"
      )

      validator.validate("550e8400-e29b-41d4-a716-446655440000", "root").valid?.should eq(true)
      validator.validate("invalid-uuid", "root").valid?.should eq(false)
    end

    it "validates hex color codes" do
      validator = Schematics::CustomValidator(String).new(
        ->(s : String) { s.matches?(/^#[0-9A-Fa-f]{6}$/) },
        "must be a valid hex color"
      )

      validator.validate("#FF5733", "root").valid?.should eq(true)
      validator.validate("#ff5733", "root").valid?.should eq(true)
      validator.validate("FF5733", "root").valid?.should eq(false)
      validator.validate("#FFF", "root").valid?.should eq(false)
    end
  end

  describe "performance with validators" do
    it "validates large datasets efficiently" do
      element_validator = Schematics::TypeValidator(Int32).new
      validator = Schematics::ArrayValidator(Int32).new(element_validator)

      large_array = Array.new(10_000) { |i| i }

      10.times do
        result = validator.validate(large_array, "root")
        result.valid?.should eq(true)
      end
    end

    it "custom validators don't add significant overhead" do
      simple_validator = Schematics::TypeValidator(Int32).new
      custom_validator = Schematics::CustomValidator(Int32).new(
        ->(n : Int32) { n > 0 },
        "must be positive"
      )

      # Both should be fast
      10_000.times do
        simple_validator.validate(42, "root")
        custom_validator.validate(42, "root")
      end
    end
  end
end
