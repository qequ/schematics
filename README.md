# schematics

a library to validate data using schemas expressed as Crystal classes

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     schematics:
       github: qequ/schematics
   ```

2. Run `shards install`

## Usage

```crystal
require "schematics"
```

Instantiate a new Schema class and define the fields you want to validate:

```crystal
    schema = Schema.new(String)
    schema.validate("hello") # => true
```

You can also validate complex arrays

```crystal
    schema = Schema.new(Array(String))
    schema.validate(["hello", "world"]) # => true
```

```crystal
    schema = Schema.new([Array(String), Int32, [[Bool]]])
    schema.validate([["hello", "world"], 1, [[true]]]) # => true
```

### Hashes

Validating hashes with basic types:

```crystal
schema = Schema.new(Hash(String, Int32))
schema.validate({"a" => 1, "b" => 2}) # => true
```

Hashes with different key types should fail:

```crystal
schema = Schema.new(Hash(String, Int32))
schema.validate({"a" => 1, 1 => 2}) # => false
```

Nested hashes:

```crystal
schema = Schema.new(Hash(String, Hash(String, Int32)))
schema.validate({"a" => {"b" => 1}, "c" => {"d" => 2}}) # => true
```

Hashes with mixed types:

```crystal
schema = Schema.new(Hash(String, Array(Int32)))
schema.validate({"a" => [1,2,3], "b" => [4,5,6]}) # => true
```

Structs

You can validate data against a struct:

```crystal
struct Person
property name : String
property age : Int32

def initialize(@name : String, @age : Int32)
end
end

schema = Schema.new(Person)
person_instance = Person.new(name: "John", age: 30)
schema.validate(person_instance) # => true
```


For more examples and advanced use cases, check the specs.



## Development

Until this version Schematics only validates Basic data types (int, string, bool, etc) and Arrays of those types or nested arrays.

Upcoming versions should parse more complex types like Hashes, Structs, etc.

### TODO

- [x] Add support for Hashes
- [x] Add support for Structs
- [ ] Add support for custom types
- [ ] Add support for custom validations


## Contributing

1. Fork it (<https://github.com/qequ/schematics/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alvaro Frias Garay](https://github.com/qequ) - creator and maintainer
