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

for more examples check the specs


## Development

Until this version Schematics only validates Basic data types (int, string, bool, etc) and Arrays of those types or nested arrays.

Upcoming versions should parse more complex types like Hashes, Structs, etc.

### TODO

- [x] Add support for Hashes
- [ ] Add support for Structs
- [ ] Add support for custom types
- [ ] Add support for custom validations


## Contributing

1. Fork it (<https://github.com/your-github-user/schematics/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alvaro Frias Garay](https://github.com/your-github-user) - creator and maintainer
