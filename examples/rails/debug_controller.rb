#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug Rails controller methods

puts "🔍 Debugging Rails Controller Methods..."
puts "=" * 45

begin
  # Load the controller
  require_relative 'hello_world_app'
  
  puts "\n1️⃣ Checking controller class hierarchy..."
  puts "HelloWorldController ancestors:"
  HelloWorldController.ancestors[0..10].each_with_index do |ancestor, i|
    puts "  #{i}: #{ancestor}"
  end
  
  puts "\n2️⃣ Checking if controller includes required modules..."
  includes_controller = HelloWorldController.included_modules.include?(RapiTapir::Server::Rails::Controller)
  puts "Includes RapiTapir::Server::Rails::Controller: #{includes_controller}"
  
  includes_input_processor = HelloWorldController.included_modules.include?(RapiTapir::Server::Rails::InputProcessor)
  puts "Includes InputProcessor: #{includes_input_processor}"
  
  includes_response_handler = HelloWorldController.included_modules.include?(RapiTapir::Server::Rails::ResponseHandler)
  puts "Includes ResponseHandler: #{includes_response_handler}"
  
  puts "\n3️⃣ Checking available instance methods..."
  controller = HelloWorldController.new
  has_process_method = controller.respond_to?(:process_rapitapir_endpoint, true)
  puts "Has process_rapitapir_endpoint method: #{has_process_method}"
  
  has_extract_inputs = controller.respond_to?(:extract_rails_inputs, true)
  puts "Has extract_rails_inputs method: #{has_extract_inputs}"
  
  has_render_response = controller.respond_to?(:render_rapitapir_response, true)
  puts "Has render_rapitapir_response method: #{has_render_response}"
  
  puts "\n4️⃣ Checking registered endpoints..."
  endpoints = HelloWorldController.rapitapir_endpoints
  puts "Registered endpoints: #{endpoints.keys}"
  
  endpoints.each do |action, config|
    puts "  #{action}: #{config[:endpoint].method} #{config[:endpoint].path}"
  end
  
  puts "\n5️⃣ Checking Rails controller methods..."
  has_render = controller.respond_to?(:render)
  puts "Has render method: #{has_render}"
  
  has_request = controller.respond_to?(:request)
  puts "Has request method: #{has_request}"
  
  has_params = controller.respond_to?(:params)
  puts "Has params method: #{has_params}"
  
  puts "\n✅ Debug complete!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace[0..5].join("\n")
end
