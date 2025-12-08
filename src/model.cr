require "./validation_result"
require "./validators"
require "json"

module Schematics
  # Model base class
  #
  # Simpler implementation using explicit field registration
  # Example:
  # ```
  # class User < Schematics::Model
  #   field email, String, required: true, validators: [min_length(5)]
  #   field age, Int32, default: 0, validators: [gte(0)]
  # end
  # ```
  abstract class Model
    @errors = {} of Symbol => Array(String)

    getter errors

    # Check if model is valid
    def valid? : Bool
      @errors.clear
      _run_validations
      validate_model if responds_to?(:validate_model)
      @errors.empty?
    end

    # Validate and raise if invalid
    def validate! : Bool
      unless valid?
        msgs = @errors.map { |f, ms| "#{f}: #{ms.join(", ")}" }.join("; ")
        raise ValidationError.new("root", msgs)
      end
      true
    end

    # Add validation error
    protected def add_error(field : Symbol, message : String)
      @errors[field] ||= [] of String
      @errors[field] << message
    end

    # Override this for custom validations
    def validate_model
    end

    # Will be implemented by subclass
    private abstract def _run_validations

    # Convert to hash
    abstract def to_h : Hash(String, JSON::Any)

    # Convert to JSON
    def to_json(io : IO) : Nil
      to_h.to_json(io)
    end

    def to_json : String
      to_h.to_json
    end

    # Field definition macro - simpler approach
    macro field(name, type, required = false, default = nil, validators = nil)
      # Generate getter/setter
      {% if default != nil %}
        property {{name.id}} : {{type}} = {{default}}
      {% elsif type.resolve.nilable? %}
        property {{name.id}} : {{type}} = nil
      {% else %}
        property {{name.id}} : {{type}}
      {% end %}

      # Add validation logic
      {% VALIDATIONS << {name.id.symbolize, type, required, validators} %}
    end

    # Generate all methods when class is finished
    macro inherited
      VALIDATIONS = [] of Tuple(Symbol, TypeNode, Bool, ASTNode | NilLiteral)

      macro finished
        # Generate initializer
        def initialize(
          \{% for field_data in VALIDATIONS %}
            \{% name = field_data[0].id %}
            \{% type = field_data[1] %}
            @\{{name}},
          \{% end %}
        )
        end

        # Generate validation method
        private def _run_validations
          \{% for field_data in VALIDATIONS %}
            \{% name = field_data[0] %}
            \{% required = field_data[2] %}
            \{% validators = field_data[3] %}

            # Check required
            \{% if required %}
              if @\{{name.id}}.nil?
                add_error(\{{name}}, "is required")
              end
            \{% end %}

            # Run validators
            \{% if validators && !validators.is_a?(NilLiteral) %}
              if val = @\{{name.id}}
                \{{validators}}.each do |validator|
                  result = validator.validate(val, \{{name.stringify}})
                  unless result.valid?
                    result.errors.each do |error|
                      add_error(\{{name}}, error.error_message)
                    end
                  end
                end
              end
            \{% end %}
          \{% end %}
        end

        # Generate to_h
        def to_h : Hash(String, JSON::Any)
          hash = {} of String => JSON::Any
          \{% for field_data in VALIDATIONS %}
            \{% name = field_data[0] %}
            \{% type = field_data[1] %}
            val = @\{{name.id}}
            \{% if type.resolve.nilable? %}
              if val.nil?
                hash[\{{name.id.stringify}}] = JSON::Any.new(nil)
              else
                \{% inner_type = type.resolve.union_types.find { |t| t != Nil } %}
                \{% if inner_type == Int32 %}
                  hash[\{{name.id.stringify}}] = JSON::Any.new(val.to_i64)
                \{% else %}
                  hash[\{{name.id.stringify}}] = JSON::Any.new(val)
                \{% end %}
              end
            \{% elsif type.resolve == Int32 %}
              hash[\{{name.id.stringify}}] = JSON::Any.new(val.to_i64)
            \{% else %}
              hash[\{{name.id.stringify}}] = JSON::Any.new(val)
            \{% end %}
          \{% end %}
          hash
        end

        # Generate from_json
        def self.from_json(json_str : String) : self
          data = JSON.parse(json_str)
          from_hash(data.as_h)
        end

        def self.from_hash(hash : Hash) : self
          new(
            \{% for field_data in VALIDATIONS %}
              \{% name = field_data[0] %}
              \{% type = field_data[1] %}
              \{{name.id}}: begin
                val = hash[\{{name.id.stringify}}]?
                if val
                  \{% if type.resolve.nilable? %}
                    \{% inner_type = type.resolve.union_types.find { |t| t != Nil } %}
                    \{% if inner_type == String %}
                      val.as_s?
                    \{% elsif inner_type == Int32 %}
                      val.as_i?.try(&.to_i32)
                    \{% elsif inner_type == Int64 %}
                      val.as_i64?
                    \{% elsif inner_type == Float64 %}
                      val.as_f?
                    \{% elsif inner_type == Bool %}
                      val.as_bool?
                    \{% else %}
                      val.as?(\{{inner_type}})
                    \{% end %}
                  \{% elsif type.resolve == String %}
                    val.as_s
                  \{% elsif type.resolve == Int32 %}
                    val.as_i.to_i32
                  \{% elsif type.resolve == Int64 %}
                    val.as_i64
                  \{% elsif type.resolve == Float64 %}
                    val.as_f
                  \{% elsif type.resolve == Bool %}
                    val.as_bool
                  \{% else %}
                    val.as(\{{type}})
                  \{% end %}
                else
                  \{% if type.resolve.nilable? %}
                    nil
                  \{% else %}
                    raise "Missing required field: " + \{{name.id.stringify}}
                  \{% end %}
                end
              end.as(\{{type}}),
            \{% end %}
          )
        end
      end
    end
  end

  # Validator helper methods (Pydantic-style)
  def self.min_length(length : Int32)
    CustomValidator(String).new(
      ->(s : String) { s.size >= length },
      "must be at least #{length} characters"
    )
  end

  def self.max_length(length : Int32)
    CustomValidator(String).new(
      ->(s : String) { s.size <= length },
      "must be at most #{length} characters"
    )
  end

  def self.format(regex : Regex)
    CustomValidator(String).new(
      ->(s : String) { s.matches?(regex) },
      "does not match required format"
    )
  end

  def self.matches(regex : Regex)
    format(regex)
  end

  def self.gte(value : Int32)
    CustomValidator(Int32).new(
      ->(n : Int32) { n >= value },
      "must be >= #{value}"
    )
  end

  def self.lte(value : Int32)
    CustomValidator(Int32).new(
      ->(n : Int32) { n <= value },
      "must be <= #{value}"
    )
  end

  def self.gt(value : Int32)
    CustomValidator(Int32).new(
      ->(n : Int32) { n > value },
      "must be > #{value}"
    )
  end

  def self.lt(value : Int32)
    CustomValidator(Int32).new(
      ->(n : Int32) { n < value },
      "must be < #{value}"
    )
  end

  def self.one_of(values : Array(String))
    CustomValidator(String).new(
      ->(s : String) { values.includes?(s) },
      "must be one of: #{values.join(", ")}"
    )
  end

  def self.range(min : Int32, max : Int32)
    CustomValidator(Int32).new(
      ->(n : Int32) { n >= min && n <= max },
      "must be between #{min} and #{max}"
    )
  end
end
