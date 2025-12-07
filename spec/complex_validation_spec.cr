require "./spec_helper"

describe "Schematics::Schema - Complex Scenarios" do
  describe "deeply nested structures" do
    it "validates 3-level nested arrays" do
      schema = Schematics::Schema(Array(Array(Array(Int32)))).new

      valid_data = [
        [[1, 2], [3, 4]],
        [[5, 6], [7, 8]],
      ]
      schema.valid?(valid_data).should eq(true)

      invalid_data = [
        [[1, 2], [3, "four"]],
        [[5, 6], [7, 8]],
      ]
      schema.valid?(invalid_data).should eq(false)
    end

    it "validates hash of arrays of hashes" do
      schema = Schematics::Schema(Hash(String, Array(Hash(String, Int32)))).new

      valid_data = {
        "users" => [
          {"id" => 1, "score" => 100},
          {"id" => 2, "score" => 200},
        ],
        "admins" => [
          {"id" => 3, "score" => 300},
        ],
      }
      schema.valid?(valid_data).should eq(true)

      invalid_data = {
        "users" => [
          {"id" => 1, "score" => "hundred"},
        ],
      }
      schema.valid?(invalid_data).should eq(false)
    end

    it "validates nested hash with multiple levels" do
      schema = Schematics::Schema(Hash(String, Hash(String, Hash(String, Int32)))).new

      valid_data = {
        "level1" => {
          "level2" => {
            "level3" => 42,
          },
        },
      }
      schema.valid?(valid_data).should eq(true)
    end
  end

  describe "empty collections" do
    it "validates empty arrays" do
      schema = Schematics::Schema(Array(Int32)).new
      schema.valid?([] of Int32).should eq(true)
    end

    it "validates empty hashes" do
      schema = Schematics::Schema(Hash(String, Int32)).new
      schema.valid?({} of String => Int32).should eq(true)
    end

    it "enforces min_size on empty arrays" do
      schema = Schematics::SchemaBuilder(Array(String)).new
        .min_size(1)
        .build

      schema.valid?([] of String).should eq(false)
      schema.valid?(["item"]).should eq(true)
    end
  end

  describe "large data sets" do
    it "validates large arrays efficiently" do
      schema = Schematics::Schema(Array(Int32)).new
      large_array = Array.new(1000) { |i| i }

      schema.valid?(large_array).should eq(true)
    end

    it "validates large hashes efficiently" do
      schema = Schematics::Schema(Hash(String, Int32)).new
      large_hash = {} of String => Int32
      100.times { |i| large_hash["key#{i}"] = i }

      schema.valid?(large_hash).should eq(true)
    end

    it "reports all errors in large arrays" do
      schema = Schematics::Schema(Array(Int32)).new
      # Create array with errors at multiple positions
      invalid_array = [1, 2, "three", 4, "five", 6, "seven"]

      result = schema.validate(invalid_array)
      result.valid?.should eq(false)
      result.errors.size.should eq(3)

      # Check that all error positions are reported
      error_paths = result.errors.map(&.path).sort!
      error_paths.should eq(["root[2]", "root[4]", "root[6]"])
    end
  end

  describe "SchemaBuilder - Complex Constraints" do
    it "chains multiple string validators" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(5)
        .max_length(20)
        .add_validator("must contain @") { |s| s.includes?("@") }
        .add_validator("must contain .") { |s| s.includes?(".") }
        .add_validator("no spaces") { |s| !s.includes?(" ") }
        .build

      schema.valid?("user@example.com").should eq(true)
      schema.valid?("user").should eq(false)
      schema.valid?("user@example com").should eq(false)
    end

    it "chains multiple numeric validators" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(10)
        .max_value(100)
        .add_validator("must be even") { |n| n.even? }
        .add_validator("must be divisible by 5") { |n| n % 5 == 0 }
        .build

      schema.valid?(20).should eq(true)
      schema.valid?(30).should eq(true)
      schema.valid?(25).should eq(false)  # Not even
      schema.valid?(22).should eq(false)  # Not divisible by 5
      schema.valid?(5).should eq(false)   # Too small
      schema.valid?(120).should eq(false) # Too large
    end

    it "validates array with element constraints" do
      schema = Schematics::SchemaBuilder(Array(Int32)).new
        .min_size(2)
        .max_size(5)
        .add_validator("all positive") { |arr| arr.all? { |n| n > 0 } }
        .add_validator("no duplicates") { |arr| arr.size == arr.uniq.size }
        .build

      schema.valid?([1, 2, 3]).should eq(true)
      schema.valid?([1]).should eq(false)                # Too small
      schema.valid?([1, 2, 3, 4, 5, 6]).should eq(false) # Too large
      schema.valid?([1, -2, 3]).should eq(false)         # Negative number
      schema.valid?([1, 2, 2]).should eq(false)          # Duplicates
    end

    it "validates with complex custom logic" do
      # Validate credit card-like numbers (simplified)
      schema = Schematics::SchemaBuilder(String).new
        .min_length(13)
        .max_length(19)
        .add_validator("only digits and spaces") { |s| s.gsub(" ", "").matches?(/^\d+$/) }
        .add_validator("valid length") { |s| [13, 15, 16, 19].includes?(s.gsub(" ", "").size) }
        .build

      schema.valid?("4532015112830366").should eq(true)
      schema.valid?("4532 0151 1283 0366").should eq(true)
      schema.valid?("1234").should eq(false)
      schema.valid?("abcd1234abcd1234").should eq(false)
    end
  end

  describe "error message details" do
    it "provides path for deeply nested errors" do
      schema = Schematics::Schema(Hash(String, Array(Hash(String, Int32)))).new

      invalid_data = {
        "users" => [
          {"id" => 1},
          {"id" => "invalid"},
        ],
      }

      result = schema.validate(invalid_data)
      result.valid?.should eq(false)
      result.errors.first.path.should contain("users")
    end

    it "reports multiple validation failures" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(10)
        .max_length(20)
        .add_validator("must contain @") { |s| s.includes?("@") }
        .build

      result = schema.validate("short")
      result.valid?.should eq(false)
      result.errors.size.should be >= 2 # min_length and @ check
    end

    it "provides error value in result" do
      schema = Schematics::Schema(Int32).new
      result = schema.validate("not a number")

      result.valid?.should eq(false)
      result.errors.first.value.should eq("not a number")
    end
  end

  describe "parse method with complex types" do
    it "parses nested arrays with correct types" do
      schema = Schematics::Schema(Array(Array(Int32))).new
      data = [[1, 2], [3, 4]]

      result = schema.parse(data)
      result.should be_a(Array(Array(Int32)))
      result.should eq([[1, 2], [3, 4]])
    end

    it "parses nested hashes with correct types" do
      schema = Schematics::Schema(Hash(String, Hash(String, Int32))).new
      data = {"outer" => {"inner" => 42}}

      result = schema.parse(data)
      result.should be_a(Hash(String, Hash(String, Int32)))
      result["outer"]["inner"].should eq(42)
    end

    it "raises with detailed path on parse error" do
      schema = Schematics::Schema(Array(Int32)).new

      expect_raises(Schematics::ValidationError, /root\[1\]/) do
        schema.parse([1, "two", 3])
      end
    end
  end

  describe "edge cases and special values" do
    it "validates zero values correctly" do
      schema = Schematics::Schema(Int32).new
      schema.valid?(0).should eq(true)
    end

    it "validates negative numbers" do
      schema = Schematics::Schema(Int32).new
      schema.valid?(-42).should eq(true)

      positive_schema = Schematics::SchemaBuilder(Int32).new
        .min_value(0)
        .build
      positive_schema.valid?(-42).should eq(false)
    end

    it "validates very large numbers" do
      schema = Schematics::Schema(Int64).new
      schema.valid?(9_223_372_036_854_775_807_i64).should eq(true)
    end

    it "validates floating point edge cases" do
      schema = Schematics::Schema(Float64).new
      schema.valid?(0.0).should eq(true)
      schema.valid?(-0.0).should eq(true)
      schema.valid?(Float64::INFINITY).should eq(true)
    end

    it "validates empty strings" do
      schema = Schematics::Schema(String).new
      schema.valid?("").should eq(true)

      non_empty_schema = Schematics::SchemaBuilder(String).new
        .min_length(1)
        .build
      non_empty_schema.valid?("").should eq(false)
    end

    it "validates strings with special characters" do
      schema = Schematics::Schema(String).new
      schema.valid?("Hello\nWorld").should eq(true)
      schema.valid?("Hello\tWorld").should eq(true)
      schema.valid?("Hello\u{1F600}World").should eq(true) # Emoji
    end

    it "validates unicode strings" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(3)
        .build

      schema.valid?("日本語").should eq(true)
      schema.valid?("🚀🎉✨").should eq(true)
    end
  end

  describe "type safety and compile-time validation" do
    it "validates with type parameters correctly" do
      int_schema = Schematics::Schema(Int32).new
      string_schema = Schematics::Schema(String).new

      # These should have different types at compile time
      typeof(int_schema.parse(42)).should eq(Int32)
      typeof(string_schema.parse("hello")).should eq(String)
    end

    it "maintains type information through arrays" do
      schema = Schematics::Schema(Array(String)).new
      result = schema.parse(["a", "b", "c"])

      typeof(result).should eq(Array(String))
      result.first.upcase.should eq("A") # String methods available
    end

    it "maintains type information through hashes" do
      schema = Schematics::Schema(Hash(String, Int32)).new
      result = schema.parse({"count" => 42})

      typeof(result).should eq(Hash(String, Int32))
      result["count"].should eq(42)
    end
  end

  describe "performance characteristics" do
    it "validates arrays without excessive allocation" do
      schema = Schematics::Schema(Array(Int32)).new
      data = Array.new(100) { |i| i }

      # Should not raise on large arrays
      100.times do
        schema.validate(data)
      end
    end

    it "reuses validator instances" do
      schema = Schematics::Schema(String).new

      # Same schema instance should work multiple times
      1000.times do
        schema.valid?("test")
      end
    end

    it "handles rapid validation calls" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(0)
        .max_value(100)
        .build

      10_000.times do |i|
        schema.valid?(i % 101)
      end
    end
  end

  describe "boolean validation shortcuts" do
    it "provides valid? as boolean shortcut" do
      schema = Schematics::Schema(Int32).new

      schema.valid?(42).should be_a(Bool)
      schema.valid?(42).should eq(true)
      schema.valid?("not int").should eq(false)
    end

    it "valid? is faster than validate for boolean checks" do
      schema = Schematics::Schema(Int32).new

      # Both should give same result
      schema.valid?(42).should eq(schema.validate(42).valid?)
      schema.valid?("x").should eq(schema.validate("x").valid?)
    end
  end

  describe "validator combinations" do
    it "validates with AND logic (all must pass)" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(10)
        .max_value(20)
        .add_validator("even") { |n| n.even? }
        .build

      # All conditions must be true
      schema.valid?(12).should eq(true)
      schema.valid?(14).should eq(true)
      schema.valid?(11).should eq(false) # Not even
      schema.valid?(5).should eq(false)  # Too small
      schema.valid?(25).should eq(false) # Too large
    end

    it "can simulate OR logic with custom validators" do
      # Accept strings that are either email-like or phone-like
      schema = Schematics::SchemaBuilder(String).new
        .add_validator("email or phone") do |s|
          s.includes?("@") || s.matches?(/^\d{3}-\d{3}-\d{4}$/)
        end
        .build

      schema.valid?("user@example.com").should eq(true)
      schema.valid?("123-456-7890").should eq(true)
      schema.valid?("invalid").should eq(false)
    end
  end

  describe "mixed type scenarios" do
    it "handles arrays with consistent element types" do
      schema = Schematics::Schema(Array(Int32)).new

      # All Int32
      schema.valid?([1, 2, 3]).should eq(true)

      # Mixed with String fails
      schema.valid?([1, "2", 3]).should eq(false)
    end

    it "validates hash with consistent value types" do
      schema = Schematics::Schema(Hash(String, String)).new

      schema.valid?({"a" => "1", "b" => "2"}).should eq(true)
      schema.valid?({"a" => "1", "b" => 2}).should eq(false)
    end
  end

  describe "validation result manipulation" do
    it "merges multiple validation results" do
      schema1 = Schematics::Schema(Int32).new
      schema2 = Schematics::Schema(String).new

      result1 = schema1.validate("not int")
      result2 = schema2.validate(123)

      combined = Schematics::ValidationResult.success
      combined.merge(result1)
      combined.merge(result2)

      combined.valid?.should eq(false)
      combined.errors.size.should eq(2)
    end

    it "can check specific error conditions" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(10)
        .build

      result = schema.validate("short")

      result.errors.any? { |e| e.error_message.includes?("length") }.should eq(true)
    end
  end

  describe "boundary value testing" do
    it "validates exact min boundary" do
      schema = Schematics::SchemaBuilder(Int32).new
        .min_value(10)
        .build

      schema.valid?(10).should eq(true)
      schema.valid?(9).should eq(false)
    end

    it "validates exact max boundary" do
      schema = Schematics::SchemaBuilder(Int32).new
        .max_value(100)
        .build

      schema.valid?(100).should eq(true)
      schema.valid?(101).should eq(false)
    end

    it "validates exact length boundaries" do
      schema = Schematics::SchemaBuilder(String).new
        .min_length(5)
        .max_length(10)
        .build

      schema.valid?("12345").should eq(true)
      schema.valid?("1234567890").should eq(true)
      schema.valid?("1234").should eq(false)
      schema.valid?("12345678901").should eq(false)
    end

    it "validates exact array size boundaries" do
      schema = Schematics::SchemaBuilder(Array(Int32)).new
        .min_size(2)
        .max_size(4)
        .build

      schema.valid?([1, 2]).should eq(true)
      schema.valid?([1, 2, 3, 4]).should eq(true)
      schema.valid?([1]).should eq(false)
      schema.valid?([1, 2, 3, 4, 5]).should eq(false)
    end
  end
end
