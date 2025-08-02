# frozen_string_literal: true

# This file demonstrates the improved auto-derivation capabilities that work
# well with Ruby's dynamic nature and lack of built-in type declarations

require_relative '../lib/rapitapir/types'

puts "=== RapiTapir Auto-Derivation Examples ==="
puts

# 1. From Hash (most reliable for Ruby)
puts "1. From Hash (recommended for Ruby)"
hash_data = {
  name: "John Doe",
  age: 30,
  email: "john@example.com",
  active: true,
  score: 95.5,
  tags: ["developer", "ruby"],
  metadata: { role: "senior", team: "backend" }
}

schema = RapiTapir::Types.from_hash(hash_data)
puts "Schema from hash:"
puts schema.field_types.inspect
puts

# 2. From Hash with filtering
filtered_schema = RapiTapir::Types.from_hash(hash_data, except: [:metadata])
puts "Schema with 'except' filtering:"
puts filtered_schema.field_types.inspect
puts

# 3. From explicit types (recommended for classes)
puts "2. From Class with Explicit Types (recommended)"
class Person
  attr_accessor :name, :age, :email, :active
end

# Method 1: Via types parameter
person_schema = RapiTapir::Types.from_object(Person, types: {
  name: :string,
  age: :integer,
  email: :string,
  active: :boolean
})
puts "Person schema with explicit types:"
puts person_schema.field_types.inspect
puts

# 4. From instance (less reliable but convenient)
puts "3. From Instance (use with well-populated data)"
person = Person.new
person.name = "Jane Smith"
person.age = 28
person.email = "jane@example.com"
person.active = true

instance_schema = RapiTapir::Types.from_object(person)
puts "Schema from instance:"
puts instance_schema.field_types.inspect
puts

# 5. From Struct (good compromise)
puts "4. From Struct (good Ruby pattern)"
Point = Struct.new(:x, :y, :z) do
  def distance_from_origin
    Math.sqrt(x**2 + y**2 + z**2)
  end
end

sample_point = Point.new(1.0, 2.0, 3.0)
point_schema = RapiTapir::Types.from_object(Point, sample: sample_point)
puts "Point schema from Struct:"
puts point_schema.field_types.inspect
puts

# 6. DSL approach (most Ruby-like)
puts "5. DSL Approach (Ruby-idiomatic)"
class User
  include RapiTapir::Types::AutoDerivation::Annotated
  
  attr_accessor :username, :email, :age, :admin
  
  rapitapir_schema do
    field :username, :string
    field :email, :string
    field :age, :integer
    field :admin, :boolean
  end
end

user_schema = RapiTapir::Types.from_object(User)
puts "User schema with DSL:"
puts user_schema.field_types.inspect
puts

# 7. OpenStruct (convenient for prototyping)
puts "6. From OpenStruct"
require 'ostruct'

config = OpenStruct.new(
  host: "localhost",
  port: 3000,
  ssl: false,
  timeout: 30.5
)

config_schema = RapiTapir::Types.from_open_struct(config)
puts "Config schema from OpenStruct:"
puts config_schema.field_types.inspect
puts

# 8. JSON Schema (for external APIs)
puts "7. From JSON Schema"
json_schema = {
  "type" => "object",
  "properties" => {
    "id" => { "type" => "integer" },
    "name" => { "type" => "string", "maxLength" => 100 },
    "email" => { "type" => "string", "format" => "email" },
    "created_at" => { "type" => "string", "format" => "date-time" },
    "tags" => { 
      "type" => "array", 
      "items" => { "type" => "string" }
    }
  },
  "required" => ["id", "name", "email"]
}

json_derived_schema = RapiTapir::Types.from_json_schema(json_schema)
puts "Schema from JSON Schema:"
puts json_derived_schema.field_types.inspect
puts

# 9. Demonstrate the limitations
puts "8. Limitations and Error Handling"

class EmptyClass
end

begin
  # This should fail gracefully
  RapiTapir::Types.from_object(EmptyClass)
rescue ArgumentError => e
  puts "Expected error for empty class: #{e.message}"
end

begin
  # This should also fail
  RapiTapir::Types.from_object(Point)  # Struct without sample
rescue ArgumentError => e
  puts "Expected error for Struct without sample: #{e.message}"
end

puts
puts "=== Recommendations ==="
puts "1. Use from_hash() for parsed JSON or config data"
puts "2. Use explicit types parameter for Ruby classes"
puts "3. Use DSL annotations for reusable schemas"
puts "4. Use Structs for value objects with samples"
puts "5. Use from_json_schema() for external API integration"
puts "6. Avoid deriving from empty classes or nil values"
