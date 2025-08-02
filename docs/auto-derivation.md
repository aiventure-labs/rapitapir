# RapiTapir Auto-Derivation Feature

## Overview

RapiTapir's Auto-Derivation feature automatically generates type schemas from structured data sources that have explicit type information. This addresses Ruby's lack of built-in type declarations by focusing on reliable sources.

## Supported Sources

### 1. JSON Schema (Primary Use Case)
Perfect for API contracts and external service integration.

```ruby
# API response schema
user_schema = {
  "type" => "object",
  "properties" => {
    "id" => { "type" => "integer" },
    "name" => { "type" => "string" },
    "email" => { "type" => "string", "format" => "email" },
    "active" => { "type" => "boolean" },
    "tags" => { "type" => "array", "items" => { "type" => "string" } }
  },
  "required" => ["id", "name", "email"]
}

# Auto-derive RapiTapir schema
USER_SCHEMA = RapiTapir::Types.from_json_schema(user_schema)
```

### 2. OpenStruct (Configuration Objects)
Great for configuration objects and dynamic data structures.

```ruby
require 'ostruct'

# Configuration object
config = OpenStruct.new(
  host: "api.example.com",
  port: 443,
  ssl: true,
  timeout: 30.5,
  features: ["auth", "logging"]
)

# Auto-derive RapiTapir schema
CONFIG_SCHEMA = RapiTapir::Types.from_open_struct(config)
```

### 3. Protobuf Messages (When Available)
Excellent for gRPC services and binary protocols.

```ruby
# Requires google-protobuf gem
USER_SCHEMA = RapiTapir::Types.from_protobuf(UserProto)
```

## Field Filtering

All methods support field filtering:

```ruby
# Include only specific fields
schema = RapiTapir::Types.from_json_schema(json_schema, only: [:id, :name])

# Exclude specific fields  
schema = RapiTapir::Types.from_json_schema(json_schema, except: [:internal_id])
```

## Supported JSON Schema Features

- **Basic Types**: string, integer, number, boolean, array, object
- **String Formats**: email, uuid, date, date-time
- **Required Fields**: Automatically handled with optional types
- **Nested Objects**: Converted to hash types
- **Arrays**: With typed items

## Type Mappings

### JSON Schema → RapiTapir
- `string` → `RapiTapir::Types.string`
- `string` (format: email) → `RapiTapir::Types.email`
- `string` (format: uuid) → `RapiTapir::Types.uuid`
- `string` (format: date) → `RapiTapir::Types.date`
- `string` (format: date-time) → `RapiTapir::Types.datetime`
- `integer` → `RapiTapir::Types.integer`
- `number` → `RapiTapir::Types.float`
- `boolean` → `RapiTapir::Types.boolean`
- `array` → `RapiTapir::Types.array(item_type)`
- `object` → `RapiTapir::Types.hash({})`

### Ruby Values → RapiTapir (OpenStruct)
- `String` → `RapiTapir::Types.string`
- `Integer` → `RapiTapir::Types.integer`
- `Float` → `RapiTapir::Types.float`
- `TrueClass/FalseClass` → `RapiTapir::Types.boolean`
- `Date` → `RapiTapir::Types.date`
- `Time/DateTime` → `RapiTapir::Types.datetime`
- `Array` → `RapiTapir::Types.array(inferred_item_type)`
- `Hash` → `RapiTapir::Types.hash({})`

## Integration Examples

### API Endpoint with JSON Schema
```ruby
# Define endpoint with auto-derived input/output schemas
api.post('/users') do |endpoint|
  endpoint
    .in(json_body(RapiTapir::Types.from_json_schema(create_user_schema)))
    .out(json_body(RapiTapir::Types.from_json_schema(user_response_schema)))
    .handle do |input|
      # Handle user creation
    end
end
```

### Configuration Validation
```ruby
# Validate configuration objects
config_schema = RapiTapir::Types.from_open_struct(default_config)

api.post('/configure') do |endpoint|
  endpoint
    .in(json_body(config_schema))
    .handle do |config|
      # Apply configuration
    end
end
```

## Benefits

1. **Reliable Type Information**: Uses sources with explicit types
2. **Reduced Boilerplate**: No manual schema definition needed
3. **External Integration**: Perfect for API contracts and third-party schemas
4. **Field Control**: Flexible filtering with only/except
5. **Error Safety**: Proper validation and error handling

## Limitations

- Ruby classes without explicit types are not supported (by design)
- Constraint validation from JSON Schema is mapped to basic types
- Protobuf support requires the google-protobuf gem

## Why This Approach?

Unlike languages with built-in type systems, Ruby's dynamic nature makes type inference unreliable. This feature focuses on sources that provide explicit type information, making auto-derivation practical and dependable for real-world use cases.
