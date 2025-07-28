# RapiTapir Endpoint DSL Reference

This document describes the RapiTapir DSL for defining HTTP API endpoints in Ruby with type safety and validation.

## Basic Usage

```ruby
require 'rapitapir'

endpoint = RapiTapir.get('/hello')
  .in(RapiTapir.query(:name, :string))
  .out(RapiTapir.json_body(message: :string))
```

## HTTP Methods

RapiTapir supports all standard HTTP methods:

```ruby
RapiTapir.get('/users')      # GET endpoint
RapiTapir.post('/users')     # POST endpoint
RapiTapir.put('/users/:id')  # PUT endpoint
RapiTapir.patch('/users/:id') # PATCH endpoint
RapiTapir.delete('/users/:id') # DELETE endpoint
RapiTapir.options('/users')  # OPTIONS endpoint
RapiTapir.head('/users')     # HEAD endpoint
```

## Input DSL Helpers

### Query Parameters
```ruby
.in(query(:name, :string))
.in(query(:age, :integer, optional: true))
.in(query(:active, :boolean))
```

### Path Parameters
```ruby
.in(path_param(:id, :integer))
.in(path_param(:slug, :string))
```

### Headers
```ruby
.in(header(:authorization, :string))
.in(header(:'content-type', :string))
```

### Request Body
```ruby
.in(body({ name: :string, email: :string }))
.in(body(User)) # Custom class
```

## Output DSL Helpers

### JSON Response
```ruby
.out(json_body({ id: :integer, name: :string }))
.out(json_body([{ id: :integer, name: :string }])) # Array
```

### XML Response
```ruby
.out(xml_body({ message: :string }))
```

### Status Codes
```ruby
.out(status_code(200))
.out(status_code(201))
.out(status_code(204))
```

### Error Responses
```ruby
.error_out(404, json_body({ error: :string }))
.error_out(422, json_body({ error: :string, details: :string }))
```

## Metadata Helpers

### Documentation
```ruby
.description('Retrieve user by ID')
.summary('Get user')
.tag('users')
```

### Lifecycle
```ruby
.deprecated(true)     # Mark as deprecated
.deprecated(false)    # Not deprecated
```

### Examples
```ruby
.example({ name: 'John', email: 'john@example.com' })
```

## Supported Types

- `:string` - String values
- `:integer` - Integer values
- `:float` - Float values (accepts integers too)
- `:boolean` - Boolean values (true/false)
- `:date` - Date objects or ISO date strings
- `:datetime` - DateTime objects or ISO datetime strings
- `Hash` - Hash schemas with typed keys
- `Class` - Custom class types

## Complete Example

```ruby
require 'rapitapir'

# Define a complete CRUD endpoint
user_endpoint = RapiTapir.post('/users')
  .in(header(:authorization, :string))
  .in(header(:'content-type', :string))
  .in(body({ 
    name: :string, 
    email: :string, 
    age: :integer,
    active: :boolean
  }))
  .out(status_code(201))
  .out(json_body({ 
    id: :integer, 
    name: :string, 
    email: :string,
    created_at: :datetime
  }))
  .error_out(400, json_body({ error: :string, details: :string }))
  .error_out(422, json_body({ 
    error: :string, 
    validation_errors: [{ field: :string, message: :string }] 
  }))
  .description('Create a new user account')
  .summary('Create user')
  .tag('users')
  .example({ name: 'John Doe', email: 'john@example.com', age: 30, active: true })

# Validate inputs and outputs
input_data = { 
  body: { name: 'John', email: 'john@example.com', age: 30, active: true }
}
output_data = {
  id: 1,
  name: 'John',
  email: 'john@example.com',
  created_at: DateTime.now
}

user_endpoint.validate!(input_data, output_data) # Returns true or raises TypeError

# Get endpoint metadata
puts user_endpoint.metadata[:description] # "Create a new user account"
puts user_endpoint.to_h # Complete hash representation
```

## Type Validation

RapiTapir performs runtime type validation:

```ruby
endpoint = RapiTapir.get('/users/:id')
  .in(path_param(:id, :integer))
  .out(json_body({ name: :string }))

# This will pass
endpoint.validate!({ id: 123 }, { name: 'John' })

# This will raise TypeError
endpoint.validate!({ id: 'abc' }, { name: 'John' })
endpoint.validate!({ id: 123 }, { name: 123 })
```

## Immutability

All endpoint operations return new endpoint instances, preserving immutability:

```ruby
base = RapiTapir.get('/users')
with_auth = base.in(header(:authorization, :string))
with_output = with_auth.out(json_body({ users: [:string] }))

# base, with_auth, and with_output are all different objects
puts base.inputs.length      # 0
puts with_auth.inputs.length # 1
puts with_output.inputs.length # 1
puts with_output.outputs.length # 1
```

## Error Handling

The DSL provides comprehensive error handling with detailed messages:

```ruby
# ArgumentError for invalid parameters
query(nil, :string)          # "Input name cannot be nil"
status_code(999)             # "Invalid status code: 999"

# TypeError for validation failures
endpoint.validate!({ name: 123 }, {}) # "Invalid type for input 'name': expected string, got Integer"
```

---

For more examples and advanced usage, see the files in the `examples/` directory and the implementation plan in `docs/blueprint.md`.
