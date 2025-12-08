# Schematics

A modern data validation library for Crystal with rich error reporting and type safety, inspired by Python's Pydantic.

## Features

- **Pydantic-Style Models**: Declarative model definitions with automatic validation
- **Type Safe**: Leverages Crystal's compile-time type system
- **Rich Validators**: Built-in validators for common use cases (length, format, ranges, etc.)
- **Custom Validators**: Fluent API for adding constraints and rules
- **JSON Serialization**: Automatic `to_json` and `from_json` methods
- **High Performance**: ~2μs per validation with zero runtime overhead
- **Composable**: Build complex schemas from simple validators

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     schematics:
       github: qequ/schematics
   ```

2. Run `shards install`

## Quick Start

### Model DSL (Recommended)

Define Pydantic-style models with declarative field definitions:

```crystal
require "schematics"

class User < Schematics::Model
  field email, String,
    required: true,
    validators: [
      Schematics.min_length(5),
      Schematics.format(/@/),
    ]

  field username, String,
    required: true,
    validators: [Schematics.min_length(3)]

  field age, Int32?,
    validators: [
      Schematics.gte(0),
      Schematics.lte(120),
    ]

  field role, String,
    default: "user",
    validators: [Schematics.one_of(["admin", "user", "guest"])]
end

# Create and validate
user = User.new(
  email: "john@example.com",
  username: "john_doe",
  age: 25,
  role: "user"
)

user.valid?  # => true
user.errors  # => {}

# JSON serialization
json = user.to_json
# => {"email":"john@example.com","username":"john_doe","age":25,"role":"user"}

# JSON deserialization
user = User.from_json(json)
```

For simpler use cases without models, see the [Schema-Based Validation](#schema-based-validation) section below.

## Model DSL

The Model DSL provides a Pydantic-style declarative approach to defining data models with automatic validation, JSON serialization, and type safety.

### Defining Models

```crystal
class Product < Schematics::Model
  field name, String,
    required: true,
    validators: [
      Schematics.min_length(1),
      Schematics.max_length(100),
    ]

  field price, Float64,
    required: true,
    validators: [Schematics.gt(0)]

  field quantity, Int32,
    default: 0,
    validators: [Schematics.gte(0)]

  field category, String,
    validators: [Schematics.one_of(["electronics", "books", "clothing"])]

  field tags, Array(String)?,
    default: nil
end
```

### Built-in Validators

#### String Validators

```crystal
# Length constraints
Schematics.min_length(5)        # Minimum 5 characters
Schematics.max_length(100)      # Maximum 100 characters

# Pattern matching
Schematics.format(/@/)          # Must contain '@'
Schematics.matches(/^[a-z]+$/)  # Only lowercase letters

# Value constraints
Schematics.one_of(["admin", "user", "guest"])  # Must be one of these values
```

#### Numeric Validators

```crystal
# Comparison operators
Schematics.gte(0)      # Greater than or equal to 0
Schematics.lte(120)    # Less than or equal to 120
Schematics.gt(0)       # Greater than 0
Schematics.lt(100)     # Less than 100

# Range constraint
Schematics.range(1, 5)  # Between 1 and 5 (inclusive)
```

### Field Options

```crystal
class User < Schematics::Model
  # Required field (must be provided at initialization)
  field email, String, required: true

  # Optional/nilable field
  field phone, String?

  # Field with default value
  field role, String, default: "user"

  # Field with validators
  field age, Int32,
    validators: [Schematics.gte(0), Schematics.lte(120)]

  # Combining options
  field username, String,
    required: true,
    validators: [
      Schematics.min_length(3),
      Schematics.max_length(20),
      Schematics.matches(/^[a-zA-Z0-9_]+$/),
    ]
end
```

### Custom Validation

Override the `validate_model` method for custom validation logic:

```crystal
class Account < Schematics::Model
  field email, String, required: true
  field age, Int32?
  field account_type, String

  def validate_model
    # Custom cross-field validation
    if age_val = age
      if age_val < 18 && account_type == "premium"
        add_error(:account_type, "Premium accounts require age 18+")
      end
    end

    # Custom email domain validation
    if email.ends_with?(".gov") && account_type != "government"
      add_error(:email, "Government emails require government account type")
    end
  end
end
```

### Validation Methods

```crystal
user = User.new(email: "test@example.com", username: "john")

# Check if valid (returns Bool)
user.valid?  # => true/false

# Get validation errors
user.errors  # => Hash(Symbol, Array(String))
# Example: {:email => ["must contain @"], :age => ["must be >= 0"]}

# Validate and raise on error
user.validate!  # Raises Schematics::ValidationError if invalid
```

### JSON Serialization

Models automatically get `to_json` and `from_json` methods:

```crystal
class Article < Schematics::Model
  field title, String
  field published, Bool
  field views, Int32
end

# To JSON
article = Article.new(title: "Hello World", published: true, views: 100)
json = article.to_json
# => {"title":"Hello World","published":true,"views":100}

# From JSON
article = Article.from_json(json)
article.title     # => "Hello World"
article.published # => true
article.views     # => 100
```

### Type Safety

Models provide compile-time type checking:

```crystal
class Post < Schematics::Model
  field title, String
  field likes, Int32
  field active, Bool
end

post = Post.new(title: "Hi", likes: 10, active: true)

# These are type-safe at compile time
title : String = post.title  # ✓ OK
likes : Int32 = post.likes   # ✓ OK
active : Bool = post.active  # ✓ OK

# Property modification
post.title = "New Title"
post.likes = 20
```

### Working with Nilable Fields

```crystal
class Profile < Schematics::Model
  field name, String, required: true
  field bio, String?         # Optional, defaults to nil
  field age, Int32?          # Optional, defaults to nil
  field avatar, String?      # Optional, defaults to nil
end

profile = Profile.new(name: "Alice", bio: nil, age: 25, avatar: nil)

# Safe access to nilable fields
if bio = profile.bio
  puts "Bio: #{bio}"
else
  puts "No bio"
end

# Or use try
profile.bio.try { |b| puts "Bio: #{b}" }
```

### Complete Example

```crystal
class BlogPost < Schematics::Model
  field title, String,
    required: true,
    validators: [
      Schematics.min_length(5),
      Schematics.max_length(200),
    ]

  field content, String,
    required: true,
    validators: [Schematics.min_length(10)]

  field author, String,
    required: true

  field tags, Array(String)?,
    default: nil

  field status, String,
    default: "draft",
    validators: [Schematics.one_of(["draft", "published", "archived"])]

  field views, Int32,
    default: 0,
    validators: [Schematics.gte(0)]

  field published_at, String?

  def validate_model
    # Custom validation: published posts must have published_at
    if status == "published" && published_at.nil?
      add_error(:published_at, "Published posts must have a published date")
    end
  end
end

# Create a blog post
post = BlogPost.new(
  title: "Getting Started with Crystal",
  content: "Crystal is a statically typed language...",
  author: "Alice",
  tags: nil,
  status: "draft",
  views: 0,
  published_at: nil
)

if post.valid?
  puts "Post is valid!"
  puts post.to_json
else
  puts "Validation errors:"
  post.errors.each do |field, messages|
    puts "  #{field}: #{messages.join(", ")}"
  end
end
```

### Performance

The Model DSL uses compile-time macros for zero runtime overhead:

```crystal
# Validation performance
10_000.times do
  user = User.new(email: "test@example.com", username: "test", age: 25, role: "user")
  user.valid?
end
```

## Schema-Based Validation

For simpler use cases without models, use the schema API directly:

### Schema Types

```crystal
# String validation
schema = Schematics::Schema(String).new
schema.valid?("hello")  # => true
schema.valid?(123)      # => false

# Integer validation
schema = Schematics::Schema(Int32).new
schema.valid?(42)  # => true

# Float validation
schema = Schematics::Schema(Float64).new
schema.valid?(3.14)  # => true
```

### Arrays

```crystal
# Homogeneous arrays
schema = Schematics::Schema(Array(Int32)).new
schema.valid?([1, 2, 3])        # => true
schema.valid?([1, "two", 3])    # => false

# Nested arrays
schema = Schematics::Schema(Array(Array(String))).new
schema.valid?([["a", "b"], ["c", "d"]])  # => true
```

### Hashes

```crystal
# Simple hashes
schema = Schematics::Schema(Hash(String, Int32)).new
schema.valid?({"a" => 1, "b" => 2})  # => true

# Nested hashes
schema = Schematics::Schema(Hash(String, Hash(String, Int32))).new
schema.valid?({"a" => {"x" => 1}, "b" => {"y" => 2}})  # => true

# Hashes with arrays
schema = Schematics::Schema(Hash(String, Array(Int32))).new
schema.valid?({"numbers" => [1, 2, 3]})  # => true
```

### Custom Validators

Build schemas with constraints using the fluent `SchemaBuilder` API:

```crystal
# String with length constraints
email_schema = Schematics::SchemaBuilder(String).new
  .min_length(5)
  .max_length(100)
  .add_validator("must contain @") { |s| s.includes?("@") }
  .build

# Number with range constraints
age_schema = Schematics::SchemaBuilder(Int32).new
  .min_value(18)
  .max_value(120)
  .build

# Array with size constraints
tags_schema = Schematics::SchemaBuilder(Array(String)).new
  .min_size(1)
  .max_size(10)
  .build
```

### Rich Error Reporting

Get detailed information about validation failures:

```crystal
schema = Schematics::Schema(Array(Int32)).new
result = schema.validate([1, 2, "three", 4, "five"])

unless result.valid?
  puts "Validation failed:"
  result.errors.each do |error|
    puts "  Path: #{error.path}"
    puts "  Message: #{error.error_message}"
    puts "  Value: #{error.value}"
  end
end

# Output:
#   Path: root[2]
#   Message: expected type Int32, got String
#   Value: three
```

### Parse with Type Safety

The `parse` method returns typed values or raises on error:

```crystal
schema = Schematics::Schema(Int32).new
value = schema.parse(42)  # Returns Int32
puts typeof(value)        # => Int32

# Raises ValidationError on invalid data
begin
  schema.parse("not a number")
rescue ex : Schematics::ValidationError
  puts ex.message  # => root: expected type Int32, got String
end
```

## Real-World Examples

### API Request Validation

```crystal
def validate_create_user(data)
  name_schema = Schematics::SchemaBuilder(String).new
    .min_length(2)
    .max_length(50)
    .build

  email_schema = Schematics::SchemaBuilder(String).new
    .min_length(5)
    .add_validator("valid email") { |s| s.includes?("@") }
    .build

  age_schema = Schematics::SchemaBuilder(Int32).new
    .min_value(18)
    .build

  errors = {} of String => String

  unless name_schema.valid?(data["name"]?)
    errors["name"] = "Invalid name"
  end

  unless email_schema.valid?(data["email"]?)
    errors["email"] = "Invalid email"
  end

  unless age_schema.valid?(data["age"]?)
    errors["age"] = "Must be 18 or older"
  end

  {valid: errors.empty?, errors: errors}
end
```

### Reusable Schemas

```crystal
module Schemas
  EMAIL = Schematics::SchemaBuilder(String).new
    .min_length(5)
    .add_validator("must be valid email") { |s| s.includes?("@") }
    .build

  POSITIVE_INT = Schematics::SchemaBuilder(Int32).new
    .min_value(1)
    .build

  USER_TAGS = Schematics::SchemaBuilder(Array(String)).new
    .min_size(1)
    .max_size(10)
    .build
end

# Use throughout your application
Schemas::EMAIL.validate("user@example.com")
Schemas::POSITIVE_INT.validate(42)
```

## Roadmap

- [x] Basic type validation
- [x] Array and Hash validation
- [x] Custom validators
- [x] Rich error reporting
- [x] Min/max constraints
- [x] Model DSL (Pydantic-style classes)
- [x] JSON serialization/deserialization
- [x] Built-in validators (length, format, ranges, one_of)
- [x] Custom validation methods
- [ ] Struct support in Model DSL
- [ ] Type coercion
- [ ] JSON Schema export
- [ ] Async validation

## Contributing

1. Fork it (<https://github.com/qequ/schematics/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alvaro Frias Garay](https://github.com/qequ) - creator and maintainer

## License

MIT License - see LICENSE file for details
