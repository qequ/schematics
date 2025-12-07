module Schematics
  # Represents a single validation error with location and message
  class ValidationError < Exception
    getter path : String
    getter value : String?

    def initialize(@path : String, error_message : String, @value : String? = nil)
      super("#{@path}: #{error_message}")
    end

    def error_message : String
      message.not_nil!
    end

    def to_s(io : IO)
      io << @path << ": " << error_message
      if v = @value
        io << " (got: " << v << ")"
      end
    end
  end

  # Result of a validation operation, containing either success or errors
  class ValidationResult
    getter errors : Array(ValidationError)

    def initialize(@errors = [] of ValidationError)
    end

    def self.success
      new
    end

    def self.failure(path : String, message : String, value = nil)
      new([ValidationError.new(path, message, value)])
    end

    def valid?
      @errors.empty?
    end

    def invalid?
      !valid?
    end

    def add_error(path : String, message : String, value = nil)
      @errors << ValidationError.new(path, message, value)
    end

    def merge(other : ValidationResult)
      @errors.concat(other.errors)
      self
    end

    def merge(other : ValidationResult, prefix : String)
      other.errors.each do |error|
        new_path = prefix.empty? ? error.path : "#{prefix}.#{error.path}"
        @errors << ValidationError.new(new_path, error.error_message, error.value)
      end
      self
    end

    def to_s(io : IO)
      if valid?
        io << "Validation successful"
      else
        io << "Validation failed with #{@errors.size} error(s):\n"
        @errors.each do |error|
          io << "  - " << error << "\n"
        end
      end
    end
  end
end
