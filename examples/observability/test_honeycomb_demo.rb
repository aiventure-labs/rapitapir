#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

# Test script to generate sample data for Honeycomb.io observability demo
class HoneycombDemoTester
  def initialize(base_url = 'http://localhost:4567')
    @base_url = base_url
    @users = []
  end

  def run_comprehensive_test
    puts "🍯 Starting comprehensive Honeycomb.io observability test"
    puts "📊 This will generate various traces to demonstrate RapiTapir + Honeycomb integration"
    puts ""

    # Test health checks
    test_health_checks

    # Create sample users
    create_sample_users

    # Test different query patterns
    test_user_queries

    # Test analytics endpoints
    test_analytics

    # Test error scenarios
    test_error_scenarios

    # Test performance scenarios
    test_performance_scenarios

    puts ""
    puts "✅ Comprehensive test completed!"
    puts "🔍 Check your Honeycomb.io dashboard to see the traces"
    puts "📈 Recommended queries to try in Honeycomb:"
    puts "   - WHERE business.operation EXISTS"
    puts "   - WHERE duration_ms > 50"
    puts "   - GROUP BY business.operation"
    puts "   - WHERE error.type EXISTS"
    puts "   - WHERE db.operation = 'SELECT'"
  end

  private

  def test_health_checks
    puts "🏥 Testing health checks..."
    
    # Basic health check
    make_request('GET', '/health')
    
    # Multiple health checks to show consistency
    3.times { make_request('GET', '/health') }
    
    puts "   ✓ Health checks completed"
  end

  def create_sample_users
    puts "👥 Creating sample users..."

    sample_users = [
      {
        name: 'Alice Johnson',
        email: 'alice.johnson@techcorp.com',
        age: 28,
        department: 'engineering'
      },
      {
        name: 'Bob Smith',
        email: 'bob.smith@techcorp.com',
        age: 34,
        department: 'sales'
      },
      {
        name: 'Carol Wilson',
        email: 'carol.wilson@techcorp.com',
        age: 29,
        department: 'marketing'
      },
      {
        name: 'David Brown',
        email: 'david.brown@techcorp.com',
        age: 31,
        department: 'engineering'
      },
      {
        name: 'Eve Davis',
        email: 'eve.davis@techcorp.com',
        age: 27,
        department: 'support'
      },
      {
        name: 'Frank Miller',
        email: 'frank.miller@techcorp.com',
        age: 35,
        department: 'sales'
      },
      {
        name: 'Grace Lee',
        email: 'grace.lee@techcorp.com',
        age: 26,
        department: 'engineering'
      },
      {
        name: 'Henry Clark',
        email: 'henry.clark@techcorp.com',
        age: 33,
        department: 'marketing'
      }
    ]

    sample_users.each_with_index do |user_data, index|
      puts "   Creating user #{index + 1}/#{sample_users.length}: #{user_data[:name]}"
      response = make_request('POST', '/users', user_data)
      
      if response && response.code == '201'
        user = JSON.parse(response.body)
        @users << user
        puts "     ✓ Created user with ID: #{user['id']}"
      else
        puts "     ❌ Failed to create user: #{user_data[:name]}"
      end
      
      # Small delay to spread out the requests
      sleep(0.1)
    end
    
    puts "   ✓ Created #{@users.length} users"
  end

  def test_user_queries
    puts "🔍 Testing user query patterns..."
    
    # Basic user listing
    puts "   Testing pagination..."
    make_request('GET', '/users')
    make_request('GET', '/users?page=1&limit=3')
    make_request('GET', '/users?page=2&limit=3')
    
    # Department filtering
    puts "   Testing department filtering..."
    %w[engineering sales marketing support].each do |dept|
      make_request('GET', "/users?department=#{dept}")
    end
    
    # Combined filtering and pagination
    puts "   Testing combined filtering..."
    make_request('GET', '/users?department=engineering&page=1&limit=2')
    
    # Individual user lookups
    puts "   Testing individual user lookups..."
    @users.first(3).each do |user|
      make_request('GET', "/users/#{user['id']}")
    end
    
    puts "   ✓ User query tests completed"
  end

  def test_analytics
    puts "📊 Testing analytics endpoints..."
    
    # Department statistics
    3.times do |i|
      puts "   Running analytics query #{i + 1}/3..."
      make_request('GET', '/analytics/department-stats')
      sleep(0.2)
    end
    
    puts "   ✓ Analytics tests completed"
  end

  def test_error_scenarios
    puts "❌ Testing error scenarios..."
    
    # Invalid JSON
    puts "   Testing invalid JSON..."
    make_request('POST', '/users', '{"invalid": json}', content_type: 'application/json', raw: true)
    
    # Validation errors
    puts "   Testing validation errors..."
    
    invalid_users = [
      { name: '', email: 'invalid', age: 15, department: 'invalid' },  # Multiple validation errors
      { name: 'John', email: 'not-an-email', age: 25, department: 'engineering' },  # Bad email
      { name: 'Jane', email: 'jane@example.com', age: 16, department: 'engineering' },  # Too young
      { name: 'Bob', email: 'bob@example.com', age: 30, department: 'nonexistent' }  # Invalid department
    ]
    
    invalid_users.each_with_index do |user_data, index|
      puts "   Testing validation error #{index + 1}/#{invalid_users.length}..."
      make_request('POST', '/users', user_data)
      sleep(0.1)
    end
    
    # Not found errors
    puts "   Testing not found errors..."
    fake_uuid = '12345678-1234-1234-1234-123456789999'
    make_request('GET', "/users/#{fake_uuid}")
    make_request('PUT', "/users/#{fake_uuid}", { name: 'Updated Name' })
    make_request('DELETE', "/users/#{fake_uuid}")
    
    puts "   ✓ Error scenario tests completed"
  end

  def test_performance_scenarios
    puts "⚡ Testing performance scenarios..."
    
    # Concurrent requests simulation
    puts "   Simulating concurrent user listing requests..."
    threads = []
    
    5.times do |i|
      threads << Thread.new do
        make_request('GET', '/users', nil, thread_id: i)
      end
    end
    
    threads.each(&:join)
    
    # Update operations
    puts "   Testing update operations..."
    if @users.any?
      user = @users.first
      update_data = {
        name: "#{user['name']} (Updated)",
        age: user['age'] + 1
      }
      make_request('PUT', "/users/#{user['id']}", update_data)
    end
    
    # Delete operations
    puts "   Testing delete operations..."
    if @users.length > 1
      user_to_delete = @users.last
      make_request('DELETE', "/users/#{user_to_delete['id']}")
    end
    
    puts "   ✓ Performance scenario tests completed"
  end

  def make_request(method, path, body = nil, content_type: 'application/json', raw: false, thread_id: nil)
    uri = URI("#{@base_url}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = case method.upcase
              when 'GET'
                Net::HTTP::Get.new(uri)
              when 'POST'
                Net::HTTP::Post.new(uri)
              when 'PUT'
                Net::HTTP::Put.new(uri)
              when 'DELETE'
                Net::HTTP::Delete.new(uri)
              else
                raise "Unsupported method: #{method}"
              end
    
    if body
      if raw
        request.body = body
      else
        request.body = body.to_json
      end
      request['Content-Type'] = content_type
    end
    
    # Add custom headers for tracing
    request['X-Test-Scenario'] = 'honeycomb-demo'
    request['X-Thread-Id'] = thread_id.to_s if thread_id
    
    begin
      response = http.request(request)
      
      status_symbol = case response.code.to_i
                      when 200..299
                        '✓'
                      when 400..499
                        '⚠'
                      else
                        '❌'
                      end
      
      thread_info = thread_id ? " [T#{thread_id}]" : ""
      puts "     #{status_symbol} #{method.upcase} #{path} → #{response.code}#{thread_info}"
      
      response
    rescue StandardError => e
      puts "     ❌ #{method.upcase} #{path} → Error: #{e.message}"
      nil
    end
  end
end

# Run the test if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.include?('--help') || ARGV.include?('-h')
    puts "Honeycomb.io Observability Demo Test Script"
    puts ""
    puts "Usage: ruby test_honeycomb_demo.rb [URL]"
    puts ""
    puts "Arguments:"
    puts "  URL    Base URL of the API server (default: http://localhost:4567)"
    puts ""
    puts "Examples:"
    puts "  ruby test_honeycomb_demo.rb"
    puts "  ruby test_honeycomb_demo.rb http://localhost:4567"
    puts ""
    puts "This script will:"
    puts "  1. Test health check endpoints"
    puts "  2. Create sample users with various departments"
    puts "  3. Test different query patterns (pagination, filtering)"
    puts "  4. Test analytics endpoints"
    puts "  5. Generate error scenarios for testing"
    puts "  6. Simulate performance scenarios"
    puts ""
    puts "All requests will generate traces in Honeycomb.io for analysis."
    puts ""
    puts "⚠️  Make sure to start the server first:"
    puts "    ruby honeycomb_working_example.rb"
    exit 0
  end

  base_url = ARGV[0] || 'http://localhost:4567'
  
  puts "🎯 Target URL: #{base_url}"
  puts ""
  
  # Check if server is running
  begin
    uri = URI("#{base_url}/health")
    response = Net::HTTP.get_response(uri)
    if response.code != '200'
      puts "❌ Server not responding correctly at #{base_url}"
      puts "   Make sure the Honeycomb demo server is running:"
      puts "   ruby examples/observability/honeycomb_working_example.rb"
      exit 1
    end
  rescue StandardError => e
    puts "❌ Cannot connect to server at #{base_url}"
    puts "   Error: #{e.message}"
    puts "   Make sure the Honeycomb demo server is running:"
    puts "   ruby examples/observability/honeycomb_working_example.rb"
    exit 1
  end
  
  tester = HoneycombDemoTester.new(base_url)
  tester.run_comprehensive_test
end
