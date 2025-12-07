require "./validation_result"

module Schematics
  # Base validator interface
  abstract class Validator(T)
    abstract def validate(value, path : String = "root") : ValidationResult
    abstract def call(value) : T?
  end

  # Validator for basic types using Crystal's type system
  class TypeValidator(T) < Validator(T)
    def validate(value, path : String = "root") : ValidationResult
      if value.is_a?(T)
        ValidationResult.success
      else
        ValidationResult.failure(path, "expected type #{T}, got #{value.class}", value.to_s)
      end
    end

    def call(value) : T?
      value.is_a?(T) ? value : nil
    end
  end

  # Validator for union types (e.g., String | Int32)
  class UnionValidator(T) < Validator(T)
    def validate(value, path : String = "root") : ValidationResult
      if value.is_a?(T)
        ValidationResult.success
      else
        ValidationResult.failure(path, "expected one of types in #{T}, got #{value.class}", value.to_s)
      end
    end

    def call(value) : T?
      value.is_a?(T) ? value : nil
    end
  end

  # Validator for optional types (Nil | T)
  class OptionalValidator(T) < Validator(T?)
    @inner_validator : Validator(T)

    def initialize(@inner_validator)
    end

    def validate(value, path : String = "root") : ValidationResult
      return ValidationResult.success if value.nil?
      @inner_validator.validate(value, path)
    end

    def call(value) : T?
      return nil if value.nil?
      @inner_validator.call(value)
    end
  end

  # Validator for Array types
  class ArrayValidator(T) < Validator(Array(T))
    @element_validator : Validator(T)
    @min_size : Int32?
    @max_size : Int32?

    def initialize(@element_validator, @min_size = nil, @max_size = nil)
    end

    def validate(value, path : String = "root") : ValidationResult
      result = ValidationResult.success

      unless value.is_a?(Array)
        return ValidationResult.failure(path, "expected Array, got #{value.class}", value.to_s)
      end

      if min = @min_size
        if value.size < min
          result.add_error(path, "array size must be at least #{min}, got #{value.size}")
        end
      end

      if max = @max_size
        if value.size > max
          result.add_error(path, "array size must be at most #{max}, got #{value.size}")
        end
      end

      value.each_with_index do |element, index|
        element_result = @element_validator.validate(element, "#{path}[#{index}]")
        result.merge(element_result)
      end

      result
    end

    def call(value) : Array(T)?
      return nil unless value.is_a?(Array)

      validated = [] of T
      value.each do |element|
        if validated_element = @element_validator.call(element)
          validated << validated_element
        else
          return nil
        end
      end
      validated
    end
  end

  # Validator for Hash types
  class HashValidator(K, V) < Validator(Hash(K, V))
    @key_validator : Validator(K)
    @value_validator : Validator(V)

    def initialize(@key_validator, @value_validator)
    end

    def validate(value, path : String = "root") : ValidationResult
      result = ValidationResult.success

      unless value.is_a?(Hash)
        return ValidationResult.failure(path, "expected Hash, got #{value.class}", value.to_s)
      end

      value.each do |key, val|
        key_result = @key_validator.validate(key, "#{path}.<key:#{key}>")
        result.merge(key_result)

        value_result = @value_validator.validate(val, "#{path}[#{key}]")
        result.merge(value_result)
      end

      result
    end

    def call(value) : Hash(K, V)?
      return nil unless value.is_a?(Hash)

      validated = {} of K => V
      value.each do |key, val|
        validated_key = @key_validator.call(key)
        validated_value = @value_validator.call(val)

        return nil if validated_key.nil? || validated_value.nil?
        validated[validated_key] = validated_value
      end
      validated
    end
  end

  # Custom validator that wraps a user-provided proc
  class CustomValidator(T) < Validator(T)
    @validator_proc : Proc(T, Bool)
    @error_message : String

    def initialize(@validator_proc, @error_message = "custom validation failed")
    end

    def validate(value, path : String = "root") : ValidationResult
      unless value.is_a?(T)
        return ValidationResult.failure(path, "expected type #{T}, got #{value.class}", value.to_s)
      end

      if @validator_proc.call(value)
        ValidationResult.success
      else
        ValidationResult.failure(path, @error_message, value.to_s)
      end
    end

    def call(value) : T?
      return nil unless value.is_a?(T)
      @validator_proc.call(value) ? value : nil
    end
  end

  # Validator chain - runs multiple validators in sequence
  class ValidatorChain(T) < Validator(T)
    @validators : Array(Validator(T))

    def initialize(validators : Array(Validator(T)))
      @validators = validators
    end

    def validate(value, path : String = "root") : ValidationResult
      result = ValidationResult.success
      @validators.each do |validator|
        result.merge(validator.validate(value, path))
      end
      result
    end

    def call(value) : T?
      @validators.each do |validator|
        result = validator.call(value)
        return nil if result.nil?
      end
      value.is_a?(T) ? value : nil
    end
  end
end
