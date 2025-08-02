# Type Shortcuts in RapiTapir

## Overview

RapiTapir provides a global `T` constant as a shortcut for `RapiTapir::Types`, making your type definitions much cleaner and more readable. **No manual setup required** - the `T` shortcut is automatically available when you `require 'rapitapir'`.

## Before vs After

### Before (Verbose)
```ruby
USER_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "name" => RapiTapir::Types.string(min_length: 1, max_length: 100),
  "email" => RapiTapir::Types.email,
  "age" => RapiTapir::Types.optional(RapiTapir::Types.integer(min: 0, max: 150))
})
```

### After (Clean)
```ruby
USER_SCHEMA = T.hash({
  "id" => T.integer,
  "name" => T.string(min_length: 1, max_length: 100),
  "email" => T.email,
  "age" => T.optional(T.integer(min: 0, max: 150))
})
```

## Automatic Availability

The `T` shortcut is **globally available** after requiring RapiTapir:

```ruby
require 'rapitapir'

# T is immediately available everywhere - no setup needed!
BOOK_SCHEMA = T.hash({
  "title" => T.string,
  "pages" => T.integer
})

class MyAPI < SinatraRapiTapir
  # T works inside classes too
  USER_SCHEMA = T.hash({
    "name" => T.string,
    "email" => T.email
  })
  
  endpoint(
    GET('/books')
      .ok(T.array(BOOK_SCHEMA)) # And in endpoint definitions
      .build
  ) { Book.all }
end
```

## All Available Type Shortcuts

```ruby
# Primitive types
T.string(min_length: 1, max_length: 255)
T.integer(minimum: 0, maximum: 100)
T.float(minimum: 0.0)
T.boolean
T.date
T.datetime
T.uuid
T.email

# Composite types
T.array(T.string)
T.hash({ "key" => T.string })
T.optional(T.string)

# Complex object types
T.object do
  field :id, T.integer
  field :name, T.string
end
```

## Usage in Endpoints

```ruby
class MyAPI < SinatraRapiTapir
  endpoint(
    GET('/users/:id')
      .path_param(:id, T.integer(minimum: 1))
      .query(:include, T.optional(T.array(T.string)))
      .ok(T.hash({
        "user" => USER_SCHEMA,
        "metadata" => T.hash({
          "version" => T.string,
          "timestamp" => T.datetime
        })
      }))
      .error_out(404, T.hash({ "error" => T.string }))
      .build
  ) do |inputs|
    # Your endpoint logic
  end
end
```

## Benefits

1. **Automatic Setup**: Available immediately after `require 'rapitapir'` - no manual configuration
2. **Readability**: Much cleaner type definitions  
3. **Less Typing**: Shorter syntax reduces boilerplate
4. **Consistency**: Same T prefix for all types
5. **Familiar**: Similar to TypeScript's type syntax
6. **Global Scope**: Works everywhere - classes, modules, top-level code
7. **Backward Compatible**: `RapiTapir::Types` still works

## Alternative Approaches

If you prefer your own shortcut, you can create it:

```ruby
# Custom shortcut (but T is already provided!)
Types = RapiTapir::Types

# Or even shorter
RT = RapiTapir::Types

# Use it
USER_SCHEMA = Types.hash({ "name" => Types.string })
```

**Note**: The global `T` constant is automatically available when you `require 'rapitapir'` - no need to define your own unless you prefer a different name.

## Implementation

The T shortcut is implemented in the main RapiTapir library file:

```ruby
# In lib/rapitapir.rb
module RapiTapir
  # ... RapiTapir module code ...
end

# Global shortcut constant
T = RapiTapir::Types
```

This means that as soon as you require RapiTapir, the `T` constant becomes available throughout your entire application.
