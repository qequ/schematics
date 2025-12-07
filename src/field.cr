require "./validation_result"
require "./validators"

module Schematics
  # Represents a field definition in a schema
  abstract class BaseField
    getter name : String
    getter required : Bool

    def initialize(@name : String, @required : Bool = true)
    end

    abstract def validate(value, path : String) : ValidationResult
    abstract def has_default? : Bool
    abstract def get_default
  end

  class Field(T) < BaseField
    getter validator : Validator(T)
    getter default : T?
    getter has_default_value : Bool

    def initialize(
      name : String,
      @validator : Validator(T),
      required : Bool = true,
      @default : T? = nil,
      @has_default_value : Bool = false
    )
      super(name, required)
    end

    def validate(value, path : String) : ValidationResult
      @validator.validate(value, path)
    end

    def has_default? : Bool
      @has_default_value
    end

    def get_default
      @default
    end

    def call(value) : T?
      @validator.call(value)
    end
  end
end
