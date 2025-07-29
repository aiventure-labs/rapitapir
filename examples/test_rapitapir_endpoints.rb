# frozen_string_literal: true

# Simple test to validate RapiTapir endpoint definitions
require_relative '../lib/rapitapir'

# Define a subset for testing
module TestTaskAPI
  extend RapiTapir::DSL

  TASK_SCHEMA = RapiTapir::Types.hash({
    "id" => RapiTapir::Types.integer,
    "title" => RapiTapir::Types.string,
    "description" => RapiTapir::Types.string,
    "status" => RapiTapir::Types.string
  })

  ERROR_SCHEMA = RapiTapir::Types.hash({
    "error" => RapiTapir::Types.string
  })

  def self.endpoints
    @endpoints ||= [
      RapiTapir.get('/health')
        .summary('Health check')
        .description('Returns the health status of the API')
        .ok(RapiTapir::Types.hash({"status" => RapiTapir::Types.string}))
        .build,

      RapiTapir.get('/api/v1/tasks')
        .summary('List all tasks')
        .description('Retrieve a list of all tasks')
        .ok(RapiTapir::Types.array(TASK_SCHEMA))
        .error_response(401, ERROR_SCHEMA, description: 'Authentication required')
        .build,

      RapiTapir.post('/api/v1/tasks')
        .summary('Create a new task')
        .description('Create a new task')
        .json_body(RapiTapir::Types.hash({
          "title" => RapiTapir::Types.string,
          "description" => RapiTapir::Types.string
        }))
        .created(TASK_SCHEMA)
        .error_response(400, ERROR_SCHEMA, description: 'Validation error')
        .build
    ]
  end

  def self.openapi_spec
    require_relative '../lib/rapitapir/openapi/schema_generator'
    
    generator = RapiTapir::OpenAPI::SchemaGenerator.new(
      endpoints: endpoints,
      info: {
        title: 'Test Task API',
        version: '1.0.0',
        description: 'Test API for validation'
      }
    )
    
    generator.generate
  end
end

# Test the endpoint definitions
puts "🧪 Testing RapiTapir Endpoint Definitions"
puts "=" * 45

begin
  endpoints = TestTaskAPI.endpoints
  puts "✅ Endpoint definitions loaded: #{endpoints.size} endpoints"
  
  endpoints.each_with_index do |endpoint, i|
    puts "   #{i+1}. #{endpoint.method.upcase} #{endpoint.path}"
    puts "      Summary: #{endpoint.metadata[:summary]}"
  end
  
  puts "\n🔍 Testing OpenAPI Generation"
  puts "-" * 30
  
  spec = TestTaskAPI.openapi_spec
  puts "✅ OpenAPI generation successful!"
  puts "   OpenAPI version: #{spec[:openapi]}"
  puts "   API title: #{spec[:info][:title]}"
  puts "   Paths defined: #{spec[:paths].keys.size}"
  
  spec[:paths].each do |path, methods|
    methods.each do |method, operation|
      puts "   #{method.upcase} #{path} - #{operation[:summary]}"
    end
  end
  
  puts "\n🎉 All tests passed! RapiTapir endpoint definitions are working correctly."
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "   Backtrace:"
  e.backtrace.first(5).each { |line| puts "     #{line}" }
  exit 1
end
