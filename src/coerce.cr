module Schematics
  # Type coercion module for converting values between compatible types
  #
  # Coercion is opt-in per field using `coerce: true`:
  # ```
  # class User < Schematics::Model
  #   field age, Int32, coerce: true   # "25" -> 25
  #   field active, Bool, coerce: true # "true" -> true
  # end
  # ```
  module Coerce
    TRUE_VALUES  = %w[1 true yes on t y]
    FALSE_VALUES = %w[0 false no off f n]

    # Coerce value to Int32
    # Accepts: Int32, Int64, Float64 (if whole number), String (numeric), Bool
    def self.to_int32(value) : Int32?
      case value
      when Int32
        value
      when Int64
        value.to_i32 if value >= Int32::MIN && value <= Int32::MAX
      when Float64
        value.to_i32 if value.finite? && value == value.floor
      when String
        value.to_i32?(strict: true)
      when Bool
        value ? 1_i32 : 0_i32
      else
        nil
      end
    end

    # Coerce value to Int64
    # Accepts: Int32, Int64, Float64 (if whole number), String (numeric), Bool
    def self.to_int64(value) : Int64?
      case value
      when Int64
        value
      when Int32
        value.to_i64
      when Float64
        value.to_i64 if value.finite? && value == value.floor
      when String
        value.to_i64?(strict: true)
      when Bool
        value ? 1_i64 : 0_i64
      else
        nil
      end
    end

    # Coerce value to Float64
    # Accepts: Float64, Int32, Int64, String (numeric)
    def self.to_float64(value) : Float64?
      case value
      when Float64
        value
      when Int32, Int64
        value.to_f64
      when String
        value.to_f64?
      else
        nil
      end
    end

    # Coerce value to Bool
    # Accepts: Bool, Int32/Int64 (0 or 1), String (true/false/yes/no/on/off/1/0)
    def self.to_bool(value) : Bool?
      case value
      when Bool
        value
      when Int32, Int64
        case value
        when 0 then false
        when 1 then true
        else        nil
        end
      when String
        lower = value.downcase
        return true if TRUE_VALUES.includes?(lower)
        return false if FALSE_VALUES.includes?(lower)
        nil
      else
        nil
      end
    end

    # Coerce value to String
    # Accepts: Any value with .to_s
    def self.to_string(value) : String?
      case value
      when String
        value
      when Int32, Int64, Float64, Bool
        value.to_s
      else
        nil
      end
    end

    # Generic coercion dispatcher based on target type
    # Used by macros to coerce JSON::Any values
    def self.coerce(value, target_type : Int32.class) : Int32?
      case value
      when JSON::Any
        to_int32(value.raw)
      else
        to_int32(value)
      end
    end

    def self.coerce(value, target_type : Int64.class) : Int64?
      case value
      when JSON::Any
        to_int64(value.raw)
      else
        to_int64(value)
      end
    end

    def self.coerce(value, target_type : Float64.class) : Float64?
      case value
      when JSON::Any
        to_float64(value.raw)
      else
        to_float64(value)
      end
    end

    def self.coerce(value, target_type : Bool.class) : Bool?
      case value
      when JSON::Any
        to_bool(value.raw)
      else
        to_bool(value)
      end
    end

    def self.coerce(value, target_type : String.class) : String?
      case value
      when JSON::Any
        to_string(value.raw)
      else
        to_string(value)
      end
    end
  end
end
