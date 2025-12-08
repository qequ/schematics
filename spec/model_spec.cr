require "./spec_helper"

# Test model classes
class TestUser < Schematics::Model
  field email, String,
    required: true,
    validators: [
      Schematics.min_length(5),
      Schematics.format(/@/),
    ]

  field username, String,
    required: true,
    validators: [Schematics.min_length(3)]
end

class TestRequiredUser < Schematics::Model
  field email, String, required: true
  field name, String
end

class TestOptionalUser < Schematics::Model
  field email, String, required: true
  field age, Int32?
end

class TestDefaultUser < Schematics::Model
  field email, String, required: true
  field role, String, default: "user"
end

class TestLengthUser < Schematics::Model
  field username, String,
    validators: [
      Schematics.min_length(3),
      Schematics.max_length(20),
    ]
end

class TestFormatUser < Schematics::Model
  field email, String,
    validators: [Schematics.format(/@/)]
  field username, String,
    validators: [Schematics.matches(/^[a-zA-Z0-9_]+$/)]
end

class TestNumericUser < Schematics::Model
  field age, Int32,
    validators: [
      Schematics.gte(0),
      Schematics.lte(120),
    ]
  field rating, Int32,
    validators: [Schematics.range(1, 5)]
end

class TestRoleUser < Schematics::Model
  field role, String,
    validators: [Schematics.one_of(["admin", "user", "guest"])]
end

class TestCustomUser < Schematics::Model
  field email, String
  field age, Int32?

  def validate_model
    if age_val = age
      if age_val < 18 && email.ends_with?(".gov")
        add_error(:email, "Government emails require age 18+")
      end
    end
  end
end

class TestMultiErrorUser < Schematics::Model
  field email, String,
    validators: [
      Schematics.min_length(5),
      Schematics.format(/@/),
    ]
  field username, String,
    validators: [Schematics.min_length(3)]
end

class TestRaisingUser < Schematics::Model
  field email, String,
    validators: [Schematics.format(/@/)]
end

class TestSerializableUser < Schematics::Model
  field email, String
  field username, String
  field age, Int32
end

class TestDeserializableUser < Schematics::Model
  field email, String
  field username, String
  field age, Int32
end

class TestNilableJsonUser < Schematics::Model
  field email, String
  field age, Int32?
end

class TestRoundtripUser < Schematics::Model
  field email, String
  field username, String
  field age, Int32
  field active, Bool, default: true
end

class TestAccessUser < Schematics::Model
  field email, String
  field age, Int32
end

class TestTypedUser < Schematics::Model
  field email, String
  field age, Int32
  field active, Bool
end

class TestNilableTypedUser < Schematics::Model
  field email, String
  field age, Int32?
end

class TestComparisonUser < Schematics::Model
  field score, Int32,
    validators: [
      Schematics.gt(0),
      Schematics.lt(100),
    ]
end

class TestClearErrorsUser < Schematics::Model
  field email, String,
    validators: [Schematics.format(/@/)]
end

class TestErrorMessagesUser < Schematics::Model
  field email, String,
    validators: [Schematics.format(/@/)]
  field username, String,
    validators: [Schematics.min_length(3)]
end

describe Schematics::Model do
  describe "field definitions" do
    it "defines fields with required validators" do
      user = TestUser.new(email: "test@example.com", username: "testuser")
      user.valid?.should be_true
      user.errors.should be_empty
    end

    it "validates required fields" do
      user = TestRequiredUser.new(email: "test@example.com", name: "John")
      user.valid?.should be_true
    end

    it "supports optional/nilable fields" do
      user = TestOptionalUser.new(email: "test@example.com", age: nil)
      user.valid?.should be_true
      user.age.should be_nil
    end

    it "supports default values" do
      user = TestDefaultUser.new(email: "test@example.com", role: "user")
      user.role.should eq("user")
      user.valid?.should be_true
    end
  end

  describe "validation" do
    it "validates string length" do
      # Valid
      user1 = TestLengthUser.new(username: "john")
      user1.valid?.should be_true

      # Too short
      user2 = TestLengthUser.new(username: "ab")
      user2.valid?.should be_false
      user2.errors[:username].should_not be_empty

      # Too long
      user3 = TestLengthUser.new(username: "a" * 25)
      user3.valid?.should be_false
      user3.errors[:username].should_not be_empty
    end

    it "validates string format/regex" do
      # Valid
      user1 = TestFormatUser.new(email: "test@example.com", username: "john_doe")
      user1.valid?.should be_true

      # Invalid email
      user2 = TestFormatUser.new(email: "invalid", username: "john_doe")
      user2.valid?.should be_false
      user2.errors[:email].should_not be_empty

      # Invalid username
      user3 = TestFormatUser.new(email: "test@example.com", username: "john-doe")
      user3.valid?.should be_false
      user3.errors[:username].should_not be_empty
    end

    it "validates numeric ranges" do
      # Valid
      user1 = TestNumericUser.new(age: 25, rating: 3)
      user1.valid?.should be_true

      # Invalid age (negative)
      user2 = TestNumericUser.new(age: -5, rating: 3)
      user2.valid?.should be_false
      user2.errors[:age].should_not be_empty

      # Invalid age (too high)
      user3 = TestNumericUser.new(age: 150, rating: 3)
      user3.valid?.should be_false
      user3.errors[:age].should_not be_empty

      # Invalid rating
      user4 = TestNumericUser.new(age: 25, rating: 10)
      user4.valid?.should be_false
      user4.errors[:rating].should_not be_empty
    end

    it "validates one_of constraint" do
      # Valid
      user1 = TestRoleUser.new(role: "admin")
      user1.valid?.should be_true

      user2 = TestRoleUser.new(role: "user")
      user2.valid?.should be_true

      # Invalid
      user3 = TestRoleUser.new(role: "superadmin")
      user3.valid?.should be_false
      user3.errors[:role].should_not be_empty
    end

    it "supports custom validation methods" do
      # Valid
      user1 = TestCustomUser.new(email: "test@agency.gov", age: 25)
      user1.valid?.should be_true

      # Invalid (underage gov email)
      user2 = TestCustomUser.new(email: "test@agency.gov", age: 16)
      user2.valid?.should be_false
      user2.errors[:email].should contain("Government emails require age 18+")
    end

    it "collects multiple validation errors" do
      user = TestMultiErrorUser.new(email: "bad", username: "ab")
      user.valid?.should be_false
      user.errors[:email].size.should eq(2)
      user.errors[:username].size.should eq(1)
    end

    it "supports validate! method that raises on error" do
      # Valid - should not raise
      user1 = TestRaisingUser.new(email: "test@example.com")
      user1.validate!.should be_true

      # Invalid - should raise
      user2 = TestRaisingUser.new(email: "invalid")
      expect_raises(Schematics::ValidationError) do
        user2.validate!
      end
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON" do
      user = TestSerializableUser.new(email: "test@example.com", username: "testuser", age: 25)
      json = user.to_json

      json.should contain("test@example.com")
      json.should contain("testuser")
      json.should contain("25")
    end

    it "deserializes from JSON" do
      json_data = %({
        "email": "bob@example.com",
        "username": "bob_builder",
        "age": 35
      })

      user = TestDeserializableUser.from_json(json_data)
      user.email.should eq("bob@example.com")
      user.username.should eq("bob_builder")
      user.age.should eq(35)
    end

    it "handles nilable fields in JSON" do
      # With nil age
      user1 = TestNilableJsonUser.new(email: "test@example.com", age: nil)
      json1 = user1.to_json
      json1.should contain("test@example.com")

      # Deserialize with missing age
      json_data = %({"email": "test2@example.com"})
      user2 = TestNilableJsonUser.from_json(json_data)
      user2.email.should eq("test2@example.com")
      user2.age.should be_nil
    end

    it "round-trips through JSON" do
      original = TestRoundtripUser.new(
        email: "test@example.com",
        username: "testuser",
        age: 30,
        active: true
      )

      json = original.to_json
      restored = TestRoundtripUser.from_json(json)

      restored.email.should eq(original.email)
      restored.username.should eq(original.username)
      restored.age.should eq(original.age)
      restored.active.should eq(original.active)
    end
  end

  describe "property access" do
    it "provides getter/setter methods" do
      user = TestAccessUser.new(email: "test@example.com", age: 25)

      # Getters
      user.email.should eq("test@example.com")
      user.age.should eq(25)

      # Setters
      user.email = "new@example.com"
      user.age = 30

      user.email.should eq("new@example.com")
      user.age.should eq(30)
    end
  end

  describe "type safety" do
    it "enforces field types" do
      user = TestTypedUser.new(email: "test@example.com", age: 25, active: true)

      # These should compile with correct types
      email_var : String = user.email
      age_var : Int32 = user.age
      active_var : Bool = user.active

      email_var.should be_a(String)
      age_var.should be_a(Int32)
      active_var.should be_a(Bool)
    end

    it "handles nilable types correctly" do
      user = TestNilableTypedUser.new(email: "test@example.com", age: nil)

      email_var : String = user.email
      age_var : Int32? = user.age

      email_var.should be_a(String)
      age_var.should be_nil
    end
  end

  describe "validator helpers" do
    it "supports gt/lt validators" do
      user1 = TestComparisonUser.new(score: 50)
      user1.valid?.should be_true

      user2 = TestComparisonUser.new(score: 0)
      user2.valid?.should be_false

      user3 = TestComparisonUser.new(score: 100)
      user3.valid?.should be_false
    end
  end

  describe "error handling" do
    it "clears errors on re-validation" do
      user = TestClearErrorsUser.new(email: "invalid")
      user.valid?.should be_false
      user.errors.should_not be_empty

      # Fix the email and re-validate
      user.email = "valid@example.com"
      user.valid?.should be_true
      user.errors.should be_empty
    end

    it "provides field-level error messages" do
      user = TestErrorMessagesUser.new(email: "invalid", username: "ab")
      user.valid?.should be_false

      user.errors[:email].should_not be_empty
      user.errors[:username].should_not be_empty
      user.errors[:email].first.should contain("format")
      user.errors[:username].first.should contain("3 characters")
    end
  end
end
