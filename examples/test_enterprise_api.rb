# frozen_string_literal: true

# Test script to demonstrate the Enterprise API
require 'net/http'
require 'json'
require 'uri'

class EnterpriseAPITester
  BASE_URL = 'http://localhost:4567'
  
  TOKENS = {
    user: 'user-token-123',
    admin: 'admin-token-456',
    readonly: 'readonly-token-789'
  }.freeze

  def initialize
    @client = Net::HTTP.new('localhost', 4567)
    @client.read_timeout = 10
  end

  def test_all
    puts "\n🧪 Testing Enterprise Task Management API"
    puts "="*50

    test_health_check
    test_openapi_spec
    test_authentication
    test_task_operations
    test_user_profile
    test_admin_operations
    test_rate_limiting_headers
    
    puts "\n✅ All tests completed!"
  end

  private

  def test_health_check
    puts "\n📊 Testing Health Check..."
    response = get_request('/health')
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "   ✅ Health: #{data['status']}"
      puts "   ✅ Version: #{data['version']}"
      puts "   ✅ Features: #{data['features'].join(', ')}"
    else
      puts "   ❌ Health check failed: #{response.code}"
    end
  end

  def test_openapi_spec
    puts "\n📚 Testing OpenAPI Documentation..."
    response = get_request('/openapi.json')
    
    if response.code == '200'
      spec = JSON.parse(response.body)
      puts "   ✅ OpenAPI version: #{spec['openapi']}"
      puts "   ✅ API title: #{spec['info']['title']}"
      puts "   ✅ Endpoints: #{spec['paths'].keys.size}"
    else
      puts "   ❌ OpenAPI spec failed: #{response.code}"
    end
  end

  def test_authentication
    puts "\n🔐 Testing Authentication..."
    
    # Test without token
    response = get_request('/api/v1/tasks')
    puts response.code == '401' ? "   ✅ Unauthorized access blocked" : "   ❌ Should block unauthorized"
    
    # Test with invalid token
    response = get_request('/api/v1/tasks', 'Bearer invalid-token')
    puts response.code == '401' ? "   ✅ Invalid token blocked" : "   ❌ Should block invalid token"
    
    # Test with valid token
    response = get_request('/api/v1/tasks', "Bearer #{TOKENS[:user]}")
    puts response.code == '200' ? "   ✅ Valid token accepted" : "   ❌ Should accept valid token"
  end

  def test_task_operations
    puts "\n📋 Testing Task Operations..."
    
    # List tasks
    response = get_request('/api/v1/tasks', "Bearer #{TOKENS[:user]}")
    if response.code == '200'
      tasks = JSON.parse(response.body)
      puts "   ✅ Listed #{tasks.size} tasks"
    end
    
    # Get specific task
    response = get_request('/api/v1/tasks/1', "Bearer #{TOKENS[:user]}")
    if response.code == '200'
      task = JSON.parse(response.body)
      puts "   ✅ Retrieved task: #{task['title']}"
    end
    
    # Create new task
    task_data = {
      title: 'API Test Task',
      description: 'Created by test script',
      assignee_id: 1,
      status: 'pending'
    }
    
    response = post_request('/api/v1/tasks', task_data, "Bearer #{TOKENS[:user]}")
    if response.code == '201'
      new_task = JSON.parse(response.body)
      puts "   ✅ Created task ID: #{new_task['id']}"
      
      # Update the task
      update_data = { status: 'in_progress' }
      response = put_request("/api/v1/tasks/#{new_task['id']}", update_data, "Bearer #{TOKENS[:user]}")
      puts response.code == '200' ? "   ✅ Updated task status" : "   ❌ Failed to update task"
      
      # Try to delete (should fail with user token)
      response = delete_request("/api/v1/tasks/#{new_task['id']}", "Bearer #{TOKENS[:user]}")
      puts response.code == '403' ? "   ✅ Delete blocked for user role" : "   ❌ Should block delete for user"
      
      # Delete with admin token
      response = delete_request("/api/v1/tasks/#{new_task['id']}", "Bearer #{TOKENS[:admin]}")
      puts response.code == '204' ? "   ✅ Admin successfully deleted task" : "   ❌ Admin should be able to delete"
    end
  end

  def test_user_profile
    puts "\n👤 Testing User Profile..."
    
    response = get_request('/api/v1/profile', "Bearer #{TOKENS[:user]}")
    if response.code == '200'
      profile = JSON.parse(response.body)
      puts "   ✅ User: #{profile['name']}"
      puts "   ✅ Role: #{profile['role']}"
      puts "   ✅ Scopes: #{profile['scopes'].join(', ')}"
      puts "   ✅ Assigned tasks: #{profile['tasks'].size}"
    end
  end

  def test_admin_operations
    puts "\n👨‍💼 Testing Admin Operations..."
    
    # Test with user token (should fail)
    response = get_request('/api/v1/admin/users', "Bearer #{TOKENS[:user]}")
    puts response.code == '403' ? "   ✅ User access to admin blocked" : "   ❌ Should block user access"
    
    # Test with admin token
    response = get_request('/api/v1/admin/users', "Bearer #{TOKENS[:admin]}")
    if response.code == '200'
      users = JSON.parse(response.body)
      puts "   ✅ Admin listed #{users.size} users"
    end
  end

  def test_rate_limiting_headers
    puts "\n⏱️  Testing Rate Limiting Headers..."
    
    response = get_request('/api/v1/tasks', "Bearer #{TOKENS[:user]}")
    if response['X-RateLimit-Remaining']
      puts "   ✅ Rate limit remaining: #{response['X-RateLimit-Remaining']}"
      puts "   ✅ Rate limit reset: #{response['X-RateLimit-Reset']}"
    else
      puts "   ℹ️  Rate limiting headers not found (middleware may be disabled)"
    end
  end

  def get_request(path, auth = nil)
    request = Net::HTTP::Get.new(path)
    request['Authorization'] = auth if auth
    request['Accept'] = 'application/json'
    @client.request(request)
  end

  def post_request(path, data, auth = nil)
    request = Net::HTTP::Post.new(path)
    request['Authorization'] = auth if auth
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(data)
    @client.request(request)
  end

  def put_request(path, data, auth = nil)
    request = Net::HTTP::Put.new(path)
    request['Authorization'] = auth if auth
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(data)
    @client.request(request)
  end

  def delete_request(path, auth = nil)
    request = Net::HTTP::Delete.new(path)
    request['Authorization'] = auth if auth
    @client.request(request)
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  puts "🧪 Enterprise API Test Suite"
  puts "Make sure the API is running on http://localhost:4567"
  puts "Start it with: ruby examples/run_enterprise_api.rb"
  puts "\nPress Enter to start testing..."
  gets
  
  tester = EnterpriseAPITester.new
  tester.test_all
end
