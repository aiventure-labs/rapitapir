# SinatraRapiTapir - Clean Base Class

## Overview

`SinatraRapiTapir` is a new base class that provides the cleanest possible syntax for creating RapiTapir APIs with Sinatra. It automatically includes all RapiTapir functionality without any manual setup.

## Before vs After

### Before (Manual Extension Registration)
```ruby
require 'sinatra/base'
require_relative '../lib/rapitapir/sinatra/extension'

class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension
  
  rapitapir do
    info(title: 'My API', version: '1.0.0')
    development_defaults!
  end

  endpoint(
    GET('/hello').ok(string_response).build
  ) { { message: 'Hello!' } }
end
```

### After (Clean Base Class)
```ruby
require_relative '../lib/rapitapir'

class MyAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'My API', version: '1.0.0')
    development_defaults!
  end

  endpoint(
    GET('/hello').ok(string_response).build
  ) { { message: 'Hello!' } }
end
```

## Key Benefits

1. **Cleaner Syntax**: `class MyAPI < SinatraRapiTapir` vs manual extension registration
2. **Fewer Requires**: Only need to require `rapitapir`, not individual extensions
3. **Automatic Setup**: Extension is automatically registered
4. **Enhanced DSL**: HTTP verb methods (GET, POST, etc.) are automatically available
5. **Full Compatibility**: Works identically to manual extension registration
6. **Type Safety**: Maintains all FluentEndpointBuilder functionality

## Features Automatically Included

- ✅ Enhanced HTTP verb DSL (`GET()`, `POST()`, `PUT()`, etc.)
- ✅ RapiTapir extension with all features
- ✅ Automatic health check endpoints
- ✅ OpenAPI documentation generation
- ✅ CORS and security middleware
- ✅ Type validation and error handling
- ✅ Authentication and authorization helpers

## Usage

The `SinatraRapiTapir` class is available in two ways:

1. **Namespaced**: `RapiTapir::SinatraRapiTapir`
2. **Top-level**: `SinatraRapiTapir` (for convenience)

Both are equivalent and can be used interchangeably.

## Examples

- `examples/hello_world.rb` - Minimal API demonstration
- `examples/getting_started_extension.rb` - Full bookstore API

## Backward Compatibility

The new base class is 100% backward compatible. Existing code using manual extension registration continues to work unchanged.

## Testing

Comprehensive test coverage is provided in `spec/sinatra/sinatra_rapitapir_spec.rb` with:
- Inheritance verification
- Enhanced DSL testing
- Feature compatibility testing
- Backward compatibility validation
