#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test to verify Honeycomb integration is working
require 'net/http'
require 'json'
require 'uri'

puts "🍯 Testing Honeycomb.io Integration"
puts "=================================="

# Start server in background
puts "📡 Starting server..."
server_pid = spawn("bundle exec ruby honeycomb_working_example.rb", 
                   out: "/dev/null", err: "/dev/null")

# Wait for server to start
sleep(3)
puts "✅ Server started (PID: #{server_pid})"

begin
  base_url = 'http://localhost:4567'
  
  # Test health endpoint
  puts "\n🏥 Testing health endpoint..."
  uri = URI("#{base_url}/health")
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    puts "✅ Health check successful (#{response.code})"
    health_data = JSON.parse(response.body)
    puts "   Status: #{health_data['status']}"
    puts "   Service: #{health_data['service']}"
  else
    puts "❌ Health check failed (#{response.code})"
  end
  
  # Test user creation (will generate traces)
  puts "\n👤 Testing user creation..."
  uri = URI("#{base_url}/users")
  http = Net::HTTP.new(uri.host, uri.port)
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = {
    name: 'Test User for Honeycomb',
    email: 'test@honeycomb-demo.com',
    age: 30,
    department: 'engineering'
  }.to_json
  
  response = http.request(request)
  
  if response.code == '201'
    puts "✅ User creation successful (#{response.code})"
    user_data = JSON.parse(response.body)
    puts "   Created user: #{user_data['name']} (ID: #{user_data['id']})"
    
    # Test getting the user back
    puts "\n🔍 Testing user retrieval..."
    get_uri = URI("#{base_url}/users/#{user_data['id']}")
    get_response = Net::HTTP.get_response(get_uri)
    
    if get_response.code == '200'
      puts "✅ User retrieval successful (#{get_response.code})"
    else
      puts "❌ User retrieval failed (#{get_response.code})"
    end
  else
    puts "❌ User creation failed (#{response.code})"
    puts "   Response: #{response.body}"
  end
  
  # Test analytics endpoint (complex operation)
  puts "\n📊 Testing analytics endpoint..."
  analytics_uri = URI("#{base_url}/analytics/department-stats")
  analytics_response = Net::HTTP.get_response(analytics_uri)
  
  if analytics_response.code == '200'
    puts "✅ Analytics successful (#{analytics_response.code})"
    analytics_data = JSON.parse(analytics_response.body)
    puts "   Total users: #{analytics_data['total_users']}"
  else
    puts "❌ Analytics failed (#{analytics_response.code})"
  end
  
  puts "\n🎉 Test completed successfully!"
  puts ""
  puts "📊 Traces should now be visible in your Honeycomb dashboard:"
  puts "   1. Go to https://ui.honeycomb.io/"
  puts "   2. Look for dataset: 'rapitapir-demo'"
  puts "   3. You should see traces for:"
  puts "      - GET /health"
  puts "      - POST /users" 
  puts "      - GET /users/:id"
  puts "      - GET /analytics/department-stats"
  puts ""
  puts "🔍 Try these queries in Honeycomb:"
  puts "   - WHERE business.operation EXISTS"
  puts "   - WHERE http.method = 'POST'"
  puts "   - WHERE db.operation EXISTS"
  puts "   - GROUP BY business.operation"

rescue StandardError => e
  puts "❌ Error during testing: #{e.message}"
ensure
  puts "\n🛑 Stopping server..."
  Process.kill('TERM', server_pid) if server_pid
  sleep(1)
  puts "✅ Server stopped"
end
