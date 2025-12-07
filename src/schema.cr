require "./validation_result"
require "./validators"

module Schematics
  # Modern Schema implementation using compile-time type checking
  class Schema(T)
    @validator : Validator(T)

    def initialize
      @validator = build_validator
    end

    # Validate data and return detailed result
    def validate(data) : ValidationResult
      @validator.validate(data, "root")
    end

    # Validate and parse data, raising on error
    def parse(data) : T
      result = validate(data)
      if result.valid?
        if parsed = @validator.call(data)
          parsed
        else
          raise ValidationError.new("root", "failed to parse data")
        end
      else
        raise result.errors.first
      end
    end

    # Validate and return boolean (backward compatible)
    def valid?(data) : Bool
      validate(data).valid?
    end

    # Build the appropriate validator based on the type T
    private def build_validator : Validator(T)
      {% if T.union? %}
        # Handle union types (e.g., String | Int32)
        UnionValidator(T).new
      {% elsif T.nilable? %}
        # Handle optional types (T?)
        inner_type = {{ T.type_vars.first }}
        inner_validator = TypeValidator(inner_type).new
        OptionalValidator(inner_type).new(inner_validator).as(Validator(T))
      {% elsif T < Array %}
        # Handle Array types
        {% element_type = T.type_vars.first %}
        element_validator = TypeValidator({{ element_type }}).new
        ArrayValidator({{ element_type }}).new(element_validator).as(Validator(T))
      {% elsif T < Hash %}
        # Handle Hash types
        {% key_type = T.type_vars[0] %}
        {% value_type = T.type_vars[1] %}
        key_validator = TypeValidator({{ key_type }}).new
        value_validator = TypeValidator({{ value_type }}).new
        HashValidator({{ key_type }}, {{ value_type }}).new(key_validator, value_validator).as(Validator(T))
      {% else %}
        # Handle basic types and structs
        TypeValidator(T).new.as(Validator(T))
      {% end %}
    end

    # Convenience method to create a schema with custom validator
    def self.with_validator(validator : Validator(T))
      schema = allocate
      schema.initialize(validator)
      schema
    end

    protected def initialize(@validator : Validator(T))
    end
  end

  # Builder for creating schemas with additional constraints
  class SchemaBuilder(T)
    @validators = [] of Validator(T)
    @base_validator : Validator(T)

    def initialize
      @base_validator = build_base_validator
      @validators << @base_validator
    end

    private def build_base_validator : Validator(T)
      {% if T.union? %}
        UnionValidator(T).new
      {% elsif T < Array %}
        {% element_type = T.type_vars.first %}
        element_validator = TypeValidator({{ element_type }}).new
        ArrayValidator({{ element_type }}).new(element_validator)
      {% elsif T < Hash %}
        {% key_type = T.type_vars[0] %}
        {% value_type = T.type_vars[1] %}
        key_validator = TypeValidator({{ key_type }}).new
        value_validator = TypeValidator({{ value_type }}).new
        HashValidator({{ key_type }}, {{ value_type }}).new(key_validator, value_validator)
      {% else %}
        TypeValidator(T).new
      {% end %}
    end

    # Add a custom validator
    def add_validator(message : String, &block : T -> Bool)
      validator = CustomValidator(T).new(block, message)
      @validators << validator
      self
    end

    # For arrays: set minimum size
    def min_size(size : Int32) forall T
      {% if T < Array %}
        @validators << CustomValidator(T).new(
          ->(arr : T) { arr.size >= size },
          "array size must be at least #{size}"
        )
      {% end %}
      self
    end

    # For arrays: set maximum size
    def max_size(size : Int32) forall T
      {% if T < Array %}
        @validators << CustomValidator(T).new(
          ->(arr : T) { arr.size <= size },
          "array size must be at most #{size}"
        )
      {% end %}
      self
    end

    # For strings: set minimum length
    def min_length(length : Int32) forall T
      {% if T == String %}
        @validators << CustomValidator(T).new(
          ->(str : T) { str.size >= length },
          "string length must be at least #{length}"
        )
      {% end %}
      self
    end

    # For strings: set maximum length
    def max_length(length : Int32) forall T
      {% if T == String %}
        @validators << CustomValidator(T).new(
          ->(str : T) { str.size <= length },
          "string length must be at most #{length}"
        )
      {% end %}
      self
    end

    # For numbers: set minimum value
    def min_value(value : T) forall T
      {% if T == Int32 || T == Int64 || T == Float64 || T == Float32 %}
        @validators << CustomValidator(T).new(
          ->(num : T) { num >= value },
          "value must be at least #{value}"
        )
      {% end %}
      self
    end

    # For numbers: set maximum value
    def max_value(value : T) forall T
      {% if T == Int32 || T == Int64 || T == Float64 || T == Float32 %}
        @validators << CustomValidator(T).new(
          ->(num : T) { num <= value },
          "value must be at most #{value}"
        )
      {% end %}
      self
    end

    # Build the final schema
    def build : Schema(T)
      if @validators.size == 1
        Schema(T).with_validator(@validators.first)
      else
        Schema(T).with_validator(ValidatorChain(T).new(@validators))
      end
    end
  end
end
