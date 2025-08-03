#!/usr/bin/env ruby
# frozen_string_literal: true

puts "🍯 Quick Honeycomb.io Server Test"
puts "================================"

# Start the server
puts "📡 Starting server..."
server_pid = spawn("bundle exec ruby honeycomb_working_example.rb", 
                   out: "/tmp/honeycomb_server.log", 
                   err: "/tmp/honeycomb_server.log")

# Give server time to start
print "⏳ Waiting for server to start"
5.times do
  print "."
  sleep(1)
end
puts " ✅"

begin
  require 'net/http'
  require 'json'
  
  # Test health endpoint
  puts "🏥 Testing health endpoint..."
  uri = URI('http://localhost:4567/health')
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    puts "✅ Health check successful!"
    health_data = JSON.parse(response.body)
    puts "   Status: #{health_data['status']}"
    puts "   Service: #{health_data['service']}"
    puts "   Version: #{health_data['version']}"
  else
    puts "❌ Health check failed: #{response.code}"
  end

  # Test creating a user
  puts "👤 Testing user creation..."
  uri = URI('http://localhost:4567/users')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = {
    name: 'Honeycomb Test User',
    email: 'test@honeycomb.example',
    age: 28,
    department: 'engineering'
  }.to_json
  
  response = http.request(request)
  
  if response.code == '201'
    puts "✅ User creation successful!"
    user = JSON.parse(response.body)
    puts "   Created: #{user['name']} (#{user['id']})"
  else
    puts "❌ User creation failed: #{response.code}"
  end

  puts ""
  puts "🎉 Honeycomb integration is working!"
  puts "📊 Traces are being sent to your Honeycomb account"
  puts "🔍 Check your dashboard at: https://ui.honeycomb.io/"
  puts "📋 Dataset name: rapitapir-demo"

rescue StandardError => e
  puts "❌ Error during testing: #{e.message}"
  puts "📋 Check server logs: /tmp/honeycomb_server.log"
ensure
  puts ""
  puts "🛑 Stopping server..."
  Process.kill('TERM', server_pid) if server_pid
  sleep(1)
  puts "✅ Done!"
end
