# frozen_string_literal: true

# RapiTapir Sinatra Extension - Hello World Example
#
# The most minimal example showing how to create a beautiful, type-safe API
# with automatic OpenAPI documentation in just a few lines of code!

require 'sinatra/base'
require_relative '../lib/rapitapir'
require_relative '../lib/rapitapir/sinatra/extension'

# Your entire API in under 20 lines! 🚀
class HelloWorldAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  # One-line API configuration
  rapitapir do
    info(title: 'Hello World API', version: '1.0.0')
    development_defaults! # Auto CORS, docs, health checks, etc.
  end

  # Hello World endpoint - beautifully typed and documented
  endpoint(
    RapiTapir.get('/hello')
      .query(:name, RapiTapir::Types.optional(RapiTapir::Types.string))
      .summary('Say hello to someone')
      .description('Returns a personalized greeting')
      .tags('Greetings')
      .ok(RapiTapir::Types.hash({
        'message' => RapiTapir::Types.string,
        'timestamp' => RapiTapir::Types.string
      }))
      .build
  ) do |inputs|
    name = inputs[:name] || 'World'
    {
      message: "Hello, #{name}!",
      timestamp: Time.now.iso8601
    }
  end

  # Another endpoint showing path parameters
  endpoint(
    RapiTapir.get('/greet/:language')
      .path_param(:language, RapiTapir::Types.string)
      .summary('Multilingual greeting')
      .tags('Greetings')
      .ok(RapiTapir::Types.hash({ 'greeting' => RapiTapir::Types.string }))
      .build
  ) do |inputs|
    greetings = {
      'english' => 'Hello!',
      'spanish' => '¡Hola!',
      'french' => 'Bonjour!',
      'italian' => 'Ciao!',
      'german' => 'Hallo!',
      'japanese' => 'こんにちは!'
    }
    
    greeting = greetings[inputs[:language].downcase] || 'Hello!'
    { greeting: greeting }
  end

  configure :development do
    puts "\n🌟 Hello World API with RapiTapir Extension"
    puts "🌐 Swagger UI:  http://localhost:4567/docs"
    puts "📋 OpenAPI:     http://localhost:4567/openapi.json"
    puts "👋 Try it:      http://localhost:4567/hello?name=Developer"
    puts "🌍 Languages:   http://localhost:4567/greet/spanish"
    puts "❤️  Health:     http://localhost:4567/health"
    puts "\n✨ Beautiful, type-safe API in under 20 lines of code!"
  end
end

HelloWorldAPI.run! if __FILE__ == $PROGRAM_NAME
