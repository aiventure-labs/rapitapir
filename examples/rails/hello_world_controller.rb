# frozen_string_literal: true

# RapiTapir Rails Integration - Hello World Example
#
# The most minimal example showing how to create a beautiful, type-safe API
# with automatic OpenAPI documentation using Rails and the enhanced RapiTapir integration!

require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/server/rails/controller_base'

# Your entire Rails API controller in under 20 lines! 🚀
class HelloWorldController < RapiTapir::Server::Rails::ControllerBase

  # One-line API configuration - same as Sinatra!
  rapitapir do
    info(title: 'Hello World Rails API', version: '1.0.0')
    development_defaults! # Enable docs, health checks, CORS, etc.
  end

  # Hello World endpoint - beautifully typed and documented using enhanced DSL
  endpoint(
    GET('/hello')
      .query(:name, T.optional(T.string), description: 'Name to greet')
      .summary('Say hello to someone')
      .description('Returns a personalized greeting with Rails magic')
      .tags('Greetings')
      .ok(T.hash({
        'message' => T.string,
        'timestamp' => T.string,
        'framework' => T.string
      }))
      .build
  ) do |inputs|
    name = inputs[:name] || 'Rails Developer'
    
    # Return data - let RapiTapir handle the rendering
    {
      message: "Hello, #{name}! Welcome to RapiTapir with Rails!",
      timestamp: Time.now.iso8601,
      framework: 'Rails + RapiTapir'
    }
  end

  # Another endpoint showing path parameters with enhanced DSL
  endpoint(
    GET('/greet/:language')
      .path_param(:language, T.string, description: 'Language for greeting')
      .summary('Multilingual greeting')
      .description('Get a greeting in different languages using Rails')
      .tags('Greetings', 'i18n')
      .ok(T.hash({ 
        'greeting' => T.string,
        'language' => T.string,
        'powered_by' => T.string
      }))
      .not_found(T.hash({ 'error' => T.string }))
      .build
  ) do |inputs|
    greetings = {
      'english' => 'Hello!',
      'spanish' => '¡Hola!',
      'french' => 'Bonjour!',
      'italian' => 'Ciao!',
      'german' => 'Hallo!',
      'japanese' => 'こんにちは!',
      'portuguese' => 'Olá!',
      'russian' => 'Привет!'
    }

    language = inputs[:language].downcase
    greeting = greetings[language]
    
    if greeting.nil?
      # Return error response structure
      { error: "Language '#{inputs[:language]}' not supported", _status: 404 }
    else
      # Return success response
      {
        greeting: greeting,
        language: language.capitalize,
        powered_by: 'RapiTapir + Rails'
      }
    end
  end

  # Demonstrate Rails-style POST endpoint with JSON body
  endpoint(
    POST('/greetings')
      .summary('Create a custom greeting')
      .description('Create a personalized greeting message')
      .tags('Greetings')
      .json_body(T.hash({
        'name' => T.string(min_length: 1),
        'greeting_style' => T.optional(T.string(enum: %w[formal casual friendly professional]))
      }))
      .created(T.hash({
        'id' => T.integer,
        'message' => T.string,
        'style' => T.string,
        'created_at' => T.string
      }))
      .bad_request(T.hash({
        'error' => T.string,
        'details' => T.array(T.string)
      }))
      .build
  ) do |inputs|
    body = inputs[:body]
    name = body['name']
    style = body['greeting_style'] || 'friendly'
    
    # Validation
    errors = []
    errors << 'Name cannot be empty' if name.nil? || name.strip.empty?
    
    if errors.any?
      # Return validation error
      { error: 'Validation failed', details: errors, _status: 400 }
    else
      # Style-based greetings
      greetings = {
        'formal' => "Good day, #{name}. It is a pleasure to make your acquaintance.",
        'casual' => "Hey #{name}! What's up?",
        'friendly' => "Hello there, #{name}! Hope you're having a great day!",
        'professional' => "Hello #{name}, welcome to our platform."
      }

      # Simulate database save with incremental ID
      greeting_id = rand(1000..9999)
      
      # Return created response
      {
        id: greeting_id,
        message: greetings[style],
        style: style,
        created_at: Time.now.iso8601,
        _status: 201
      }
    end
  end

  # Health check endpoint (will be auto-generated in future versions)
  endpoint(
    GET('/health')
      .summary('Health check')
      .description('Check if the Rails API is running')
      .tags('System')
      .ok(T.hash({
        'status' => T.string,
        'timestamp' => T.string,
        'framework' => T.string,
        'ruby_version' => T.string
      }))
      .build
  ) do |inputs|
    # Return health status data
    {
      status: 'healthy',
      timestamp: Time.now.iso8601,
      framework: "Rails #{Rails.version rescue 'Unknown'} + RapiTapir",
      ruby_version: RUBY_VERSION
    }
  end

  # Custom action demonstrating Rails conventions
  def welcome
    render json: {
      message: 'Welcome to RapiTapir with Rails!',
      documentation: 'Visit /docs for interactive API documentation',
      examples: {
        hello: '/hello?name=YourName',
        greet: '/greet/spanish',
        health: '/health'
      }
    }
  end

  private

  # Rails-style before_action can still be used
  # before_action :log_request, only: [:hello, :greet]

  def log_request
    Rails.logger.info "RapiTapir request: #{request.method} #{request.path}"
  end
end
