# Schematics

A modern data validation library for Crystal with rich error reporting and type safety, inspired by Python's Pydantic.

## Features

- **Type Safe**: Leverages Crystal's compile-time type system
- **Custom Validators**: Fluent API for adding constraints and rules
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

```crystal
require "schematics"

# Basic type validation
schema = Schematics::Schema(String).new
result = schema.validate("hello")

if result.valid?
  puts "Valid!"
else
  result.errors.each { |error| puts error }
end

# Or use the boolean shortcut
schema.valid?("hello")  # => true
```

## Usage Examples

### Basic Types

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
- [ ] Model DSL (Pydantic-style classes)
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
