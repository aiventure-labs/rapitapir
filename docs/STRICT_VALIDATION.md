# Strict Validation by Default - Implementation Summary

## Overview

This document outlines the implementation of strict validation as the default behavior for RapiTapir v2.0 hash schemas, addressing security concerns about unexpected fields in API payloads.

## Problem Statement

**Before**: RapiTapir allowed additional properties in hash schemas by default:
```ruby
# This would succeed even with extra fields
BOOK_SCHEMA = RapiTapir::Types.hash({
  'title' => RapiTapir::Types.string,
  'author' => RapiTapir::Types.string
})

# Request with extra fields would be accepted
{
  "title": "Book Title",
  "author": "Author Name", 
  "malicious_field": "unexpected_data"  # ❌ Should be rejected
}
```

**Security Issues**:
- Data leakage through unvalidated fields
- Potential injection attacks via unexpected parameters
- API contract violations going unnoticed
- Difficulty in maintaining data integrity

## Solution Implemented

### 1. Changed Default Behavior

**File**: `lib/rapitapir/types/hash.rb`

**Change**: Modified default `additional_properties` from `true` to `false`

```ruby
# Before
def initialize(field_types = {}, additional_properties: true, **options)

# After  
def initialize(field_types = {}, additional_properties: false, **options)
```

### 2. Added Coercion-Time Validation

**Added Method**: `validate_no_unexpected_fields`

```ruby
def validate_no_unexpected_fields(value)
  expected_keys = field_types.keys.map { |k| [k, k.to_s, k.to_sym] }.flatten.uniq
  unexpected_keys = value.keys - expected_keys
  return if unexpected_keys.empty?

  unexpected_list = unexpected_keys.map(&:inspect).join(', ')
  raise CoercionError.new(value, 'Hash', "Unexpected fields in hash: #{unexpected_list}. Only these fields are allowed: #{field_types.keys.join(', ')}")
end
```

**Integration**: Added check in `coerce_hash_value` method:

```ruby
def coerce_hash_value(value)
  coerced = {}

  # Check for unexpected fields if additional properties are not allowed
  validate_no_unexpected_fields(value) unless constraints[:additional_properties]
  
  # ... rest of coercion
end
```

### 3. Added Explicit Opt-in for Flexible Schemas

**File**: `lib/rapitapir/types.rb`

**New Method**: `open_hash` for when additional properties are needed

```ruby
def self.open_hash(field_types = {}, **options)
  Hash.new(field_types, additional_properties: true, **options)
end
```

## Usage Examples

### Strict Validation (Default)

```ruby
# Strict by default - rejects unexpected fields
STRICT_SCHEMA = RapiTapir::Types.hash({
  'name' => RapiTapir::Types.string,
  'email' => RapiTapir::Types.email
})

# ✅ Valid request
{ "name": "John", "email": "john@example.com" }

# ❌ Rejected request
{ 
  "name": "John", 
  "email": "john@example.com",
  "extra_field": "unexpected"  # Causes validation error
}
```

### Open Validation (Explicit Opt-in)

```ruby
# Explicitly allow additional properties
FLEXIBLE_SCHEMA = RapiTapir::Types.open_hash({
  'name' => RapiTapir::Types.string,
  'email' => RapiTapir::Types.email
})

# ✅ Valid request with extra fields
{ 
  "name": "John", 
  "email": "john@example.com",
  "custom_field": "allowed"  # Accepted
}
```

## Error Messages

### Before
```json
{
  "error": "Internal Server Error",
  "message": "Generic error message"
}
```

### After
```json
{
  "error": "Validation Error",
  "message": "Unexpected fields in hash: \"extra_field\", \"another_field\". Only these fields are allowed: title, author, isbn, published",
  "field": null,
  "value": {...},
  "expected_type": "Hash"
}
```

## Security Benefits

### 🔒 **Enhanced Security**
- **Prevents data injection**: Unexpected fields are rejected at the validation layer
- **Reduces attack surface**: Limits what data can be passed to application logic
- **Contract enforcement**: Ensures API only accepts explicitly defined data

### 🛡️ **Data Integrity**
- **Schema compliance**: Guarantees data matches expected structure
- **Prevents pollution**: Stops unvalidated data from entering the system
- **Clear boundaries**: Explicit definition of acceptable input

### 📋 **Developer Experience**
- **Clear errors**: Specific messages about which fields are unexpected
- **Explicit intent**: Developers must consciously choose to allow extra fields
- **Better debugging**: Easier to track down validation issues

## When to Use Each Approach

### Use Strict Validation (Default) For:
- ✅ **Production APIs** - Maximum security and data integrity
- ✅ **User input forms** - Prevent form tampering
- ✅ **Payment/financial data** - Critical data validation
- ✅ **Authentication payloads** - Security-sensitive endpoints
- ✅ **Most API endpoints** - Default choice for better security

### Use Open Validation (`open_hash`) For:
- 🌐 **Webhook payloads** - Third-party services with varying data
- 🔧 **Configuration objects** - User-defined custom fields
- 📦 **Migration endpoints** - Backward compatibility needs
- 🔄 **Proxy/transformation APIs** - Pass-through scenarios
- 📊 **Analytics events** - Variable event properties

## Backward Compatibility

### Breaking Change Considerations
- **Default behavior changed**: Existing code may need updates
- **Migration path**: Replace `Types.hash()` with `Types.open_hash()` where needed
- **Gradual adoption**: Can be implemented endpoint by endpoint

### Recommended Migration Strategy
1. **Audit existing schemas**: Identify which endpoints need flexible validation
2. **Update specific cases**: Change to `open_hash()` only where required
3. **Test thoroughly**: Verify all endpoints work with strict validation
4. **Monitor errors**: Watch for unexpected field rejections in production

## Testing

All implementations have been tested with:
- ✅ Unit tests for strict validation behavior
- ✅ Integration tests with Sinatra adapter
- ✅ Error message format verification
- ✅ Backward compatibility checks
- ✅ Performance impact assessment

## Files Modified

1. **`lib/rapitapir/types/hash.rb`**
   - Changed default `additional_properties: false`
   - Added `validate_no_unexpected_fields` method
   - Enhanced coercion-time validation

2. **`lib/rapitapir/types.rb`**
   - Added `open_hash()` factory method
   - Maintained existing `hash()` method with new defaults

3. **`examples/strict_validation_examples.rb`**
   - Comprehensive usage examples
   - Security benefit demonstrations

## Impact Assessment

### Performance
- **Minimal overhead**: Additional validation only when needed
- **Early rejection**: Fails fast on invalid data
- **Efficient checks**: Simple key comparison operations

### Security Posture
- **Significantly improved**: Default-secure behavior
- **Reduced risk**: Fewer attack vectors through unexpected data
- **Compliance friendly**: Better for regulatory requirements

This implementation makes RapiTapir more secure by default while maintaining flexibility for specific use cases that require it.
