# custom error when validation fails
class ValidationError < Exception
  def initialize(msg)
    super(msg)
  end
end

# class Schema to serve as validator for json schema againts a schema given by user
class Schema(T)
  # set @schema type to be any
  def initialize(schema : T)
    @schema = schema
  end

  def validate(data)
    handler = ArrayDataTypeHandler.new
    handler.setNext(StructDataTypeHandler.new)
    handler.setNext(HashDataTypeHandler.new)
    handler.setNext(BasicDataTypeHandler.new)
    handler.handle(data, @schema)
  end
end

# interface Handler for chain of responsibility pattern

class Handler
  def initialize
    @successor = nil
  end

  def handle(data, schema)
    raise NotImplementedError.new("#{self.class} has not implemented method")
  end

  def setNext(handler : Handler)
    @successor = handler
    return handler
  end
end

# concrete handler for basic data type of schema
class BasicDataTypeHandler < Handler
  def checkSchemaIsBasicType(schema)
    return schema.is_a?(String) ||
      schema.is_a?(Int) ||
      schema.is_a?(Int8) ||
      schema.is_a?(Int16) ||
      schema.is_a?(Int32) ||
      schema.is_a?(Int64) ||
      schema.is_a?(UInt8) ||
      schema.is_a?(UInt16) ||
      schema.is_a?(UInt32) ||
      schema.is_a?(UInt64) ||
      schema.is_a?(Float) ||
      schema.is_a?(Float32) ||
      schema.is_a?(Float64) ||
      schema.is_a?(Bool) ||
      schema.is_a?(Char) ||
      schema.is_a?(Class) ||
      schema.is_a?(Nil)
  end

  def handle(data, schema)
    if checkSchemaIsBasicType(schema)
      # compare data with schema
      # get type of data
      return data == schema || data.class == schema
    else
      @successor.try &.handle(data, schema)
    end
  end
end

# concrete handler for array data type of schema
class ArrayDataTypeHandler < Handler
  # method to check if two arrays are of the same length
  def checkArrayLength(data, schema)
    return data.size == schema.size
  end

  # method to check if given a data and current schema, the data is valid creating a new schema
  def checkCurrentdata(data, current_schema)
    return Schema.new(current_schema).validate(data)
  end

  def handle(data, schema)
    if schema.is_a?(Array)
      if data.is_a?(Array)
        if checkArrayLength(data, schema)
          # iterate over array index
          (0..data.size - 1).each do |i|
            if !checkCurrentdata(data[i], schema[i])
              return false
            end
          end
          return true
        else
          return false
        end
      else
        return false
      end
    else
      @successor.try &.handle(data, schema)
    end
  end
end

# concrete handler for hash data type of schema
class HashDataTypeHandler < Handler
  # method to check if given a data and current schema, the data is valid creating a new schema
  def checkCurrentdata(data, current_schema)
    return Schema.new(current_schema).validate(data)
  end

  def handle(data, schema)
    if schema.is_a?(Hash)
      if data.is_a?(Hash)
        # Iterate over each key-value pair in the data
        data.each do |key, value_data|
          # Get the expected type from the schema (default to Nil if not specified)
          value_schema = schema[key]? || Nil
          # Validate each value in the data hash against its corresponding schema
          unless checkCurrentdata(value_data, value_schema)
            return false
          end
        end
        return true
      else
        return false
      end
    else
      @successor.try &.handle(data, schema)
    end
  end
end


# concrete handler for struct data type of schema
class StructDataTypeHandler < Handler
  def handle(data, schema)
    # If both data and schema are of type Struct, compare their string representations
    if data.is_a?(Struct) && schema.is_a?(Struct)
      return data.to_s == schema.to_s
    else
      @successor.try &.handle(data, schema)
    end
  end
end
