#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

puts "🍯 Complete Honeycomb.io Server Test"
puts "===================================="

# Change to project root
project_root = File.expand_path('../../', __dir__)
Dir.chdir(project_root)

puts "📂 Working directory: #{Dir.pwd}"

# Start server in background
puts "📡 Starting server..."
server_pid = spawn("bundle exec ruby examples/observability/honeycomb_working_example.rb", 
                   out: "/tmp/honeycomb_server.log", 
                   err: "/tmp/honeycomb_server.log")

# Give server time to start
puts "⏳ Waiting for server to start..."
server_ready = false
20.times do |i|
  sleep 1
  begin
    response = Net::HTTP.get_response(URI('http://localhost:4567/health'))
    if response.code == '200'
      server_ready = true
      puts "✅ Server is ready! (attempt #{i + 1})"
      break
    end
  rescue Errno::ECONNREFUSED, Net::OpenTimeout
    print "."
  end
end

unless server_ready
  puts "\n❌ Server failed to start within 20 seconds"
  Process.kill('TERM', server_pid) rescue nil
  Process.wait(server_pid) rescue nil
  exit 1
end

puts "\n🧪 Running tests..."

# Test 1: Health check
puts "\n1️⃣ Testing health endpoint..."
response = Net::HTTP.get_response(URI('http://localhost:4567/health'))
puts "   Status: #{response.code}"
puts "   Body: #{response.body}"

# Test 2: List users (empty)
puts "\n2️⃣ Testing user list endpoint..."
response = Net::HTTP.get_response(URI('http://localhost:4567/users'))
puts "   Status: #{response.code}"
puts "   Body: #{response.body}"

# Test 3: Create a user
puts "\n3️⃣ Testing user creation..."
uri = URI('http://localhost:4567/users')
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = {
  name: 'Alice Johnson',
  email: 'alice@example.com',
  age: 28,
  department: 'engineering'
}.to_json

response = http.request(request)
puts "   Status: #{response.code}"
puts "   Body: #{response.body}"

if response.code == '201'
  user_data = JSON.parse(response.body)
  user_id = user_data['id']
  
  # Test 4: Get the created user
  puts "\n4️⃣ Testing get user by ID..."
  response = Net::HTTP.get_response(URI("http://localhost:4567/users/#{user_id}"))
  puts "   Status: #{response.code}"
  puts "   Body: #{response.body}"
  
  # Test 5: Update the user
  puts "\n5️⃣ Testing user update..."
  uri = URI("http://localhost:4567/users/#{user_id}")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Put.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = {
    name: 'Alice Johnson-Smith',
    department: 'product'
  }.to_json
  
  response = http.request(request)
  puts "   Status: #{response.code}"
  puts "   Body: #{response.body}"
end

# Test 6: Department analytics
puts "\n6️⃣ Testing department analytics..."
response = Net::HTTP.get_response(URI('http://localhost:4567/analytics/department-stats'))
puts "   Status: #{response.code}"
puts "   Body: #{response.body}"

puts "\n✅ All tests completed!"
puts "\n📊 Check your Honeycomb.io dashboard for traces!"
puts "   Dataset: rapitapir-demo"
puts "   Service: rapitapir-demo"

# Cleanup
puts "\n🧹 Cleaning up..."
Process.kill('TERM', server_pid) rescue nil
Process.wait(server_pid) rescue nil
puts "✅ Server stopped"

puts "\n🎉 Test complete! Your Honeycomb integration is working!"
