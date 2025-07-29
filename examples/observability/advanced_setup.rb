# frozen_string_literal: true

require 'rapitapir'
require 'rack'

# Advanced observability configuration
RapiTapir.configure do |config|
  # Comprehensive metrics setup
  config.metrics.enable_prometheus(
    namespace: 'ecommerce_api',
    labels: { 
      service: 'order_service',
      version: ENV['APP_VERSION'] || '1.0.0',
      environment: ENV['RAILS_ENV'] || 'development'
    }
  )
  
  # Detailed tracing configuration
  config.tracing.enable_opentelemetry(
    service_name: 'ecommerce-order-api',
    service_version: ENV['APP_VERSION'] || '1.0.0'
  )
  
  # Structured logging with custom fields
  config.logging.enable_structured(
    level: :info,
    fields: [
      :timestamp, :level, :message, :request_id, 
      :method, :path, :status, :duration,
      :user_id, :tenant_id, :trace_id, :span_id
    ]
  )
  
  # Comprehensive health checks
  config.health_check.enable(endpoint: '/health')
  
  # Database health check
  config.health_check.add_check(:database) do
    begin
      # Simulate database connection check
      start_time = Time.now
      # ActiveRecord::Base.connection.execute("SELECT 1")
      duration = Time.now - start_time
      
      {
        status: :healthy,
        message: "Database connection successful",
        response_time_ms: (duration * 1000).round(2)
      }
    rescue => e
      {
        status: :unhealthy,
        message: "Database connection failed: #{e.message}"
      }
    end
  end
  
  # Redis health check
  config.health_check.add_check(:redis) do
    begin
      # Simulate Redis connection check
      start_time = Time.now
      # Redis.current.ping
      duration = Time.now - start_time
      
      {
        status: :healthy,
        message: "Redis connection successful",
        response_time_ms: (duration * 1000).round(2)
      }
    rescue => e
      {
        status: :unhealthy,
        message: "Redis connection failed: #{e.message}"
      }
    end
  end
  
  # External API health check
  config.health_check.add_check(:payment_gateway) do
    begin
      # Simulate external API health check
      start_time = Time.now
      # HTTP.get("https://api.stripe.com/v1/charges", headers: { "Authorization" => "Bearer sk_test_..." })
      duration = Time.now - start_time
      
      if duration > 5.0 # More than 5 seconds is concerning
        {
          status: :warning,
          message: "Payment gateway responding slowly",
          response_time_ms: (duration * 1000).round(2)
        }
      else
        {
          status: :healthy,
          message: "Payment gateway connection successful",
          response_time_ms: (duration * 1000).round(2)
        }
      end
    rescue => e
      {
        status: :unhealthy,
        message: "Payment gateway unreachable: #{e.message}"
      }
    end
  end
end

# Define order schema
OrderSchema = {
  customer_id: :uuid,
  items: [{
    product_id: :uuid,
    quantity: { type: :integer, minimum: 1 },
    price: { type: :float, minimum: 0.01 }
  }],
  shipping_address: {
    street: :string,
    city: :string,
    state: :string,
    zip_code: :string,
    country: :string
  },
  payment_method: {
    type: { type: :string, enum: ['credit_card', 'paypal', 'bank_transfer'] },
    details: :object
  }
}

# Create order endpoint with comprehensive observability
create_order_endpoint = RapiTapir.endpoint
  .post
  .in("/orders")
  .header(:authorization, Types.string(pattern: /\ABearer .+\z/), description: "JWT token")
  .header(:'x-tenant-id', :uuid, description: "Tenant identifier")
  .json_body(OrderSchema)
  .out_json({
    id: :uuid,
    status: { type: :string, enum: ['pending', 'confirmed', 'processing', 'shipped', 'delivered'] },
    customer_id: :uuid,
    total_amount: :float,
    items: [{
      product_id: :uuid,
      quantity: :integer,
      unit_price: :float,
      total_price: :float
    }],
    created_at: :datetime,
    updated_at: :datetime
  })
  .with_metrics("order_creation")
  .with_tracing("POST /orders")
  .with_logging(
    level: :info,
    fields: [:customer_id, :order_id, :total_amount, :item_count, :tenant_id]
  )
  .description("Create a new order")
  .tag("orders")
  .handle do |request|
    # Extract context from headers
    tenant_id = request.headers[:'x-tenant-id']
    auth_token = request.headers[:authorization]
    
    # Add context to tracing
    RapiTapir::Observability::Tracing.set_attribute('tenant.id', tenant_id)
    RapiTapir::Observability::Tracing.set_attribute('auth.type', 'bearer')
    
    order_data = request.body
    customer_id = order_data[:customer_id]
    total_amount = calculate_total_amount(order_data[:items])
    item_count = order_data[:items].length
    
    # Add business metrics to tracing
    RapiTapir::Observability::Tracing.set_attribute('order.customer_id', customer_id)
    RapiTapir::Observability::Tracing.set_attribute('order.total_amount', total_amount)
    RapiTapir::Observability::Tracing.set_attribute('order.item_count', item_count)
    
    # Structured logging
    RapiTapir::Observability::Logging.info(
      "Processing order creation",
      customer_id: customer_id,
      total_amount: total_amount,
      item_count: item_count,
      tenant_id: tenant_id
    )
    
    begin
      # Simulate order processing with nested spans
      order_id = RapiTapir::Observability::Tracing.start_span("validate_order") do
        # Validation logic
        validate_order(order_data)
        SecureRandom.uuid
      end
      
      RapiTapir::Observability::Tracing.start_span("process_payment") do |span|
        span.set_attribute('payment.method', order_data[:payment_method][:type])
        span.set_attribute('payment.amount', total_amount)
        
        # Simulate payment processing
        payment_result = process_payment(order_data[:payment_method], total_amount)
        span.set_attribute('payment.transaction_id', payment_result[:transaction_id])
        
        # Add payment event
        RapiTapir::Observability::Tracing.add_event(
          'payment.processed',
          attributes: {
            'payment.status' => payment_result[:status],
            'payment.transaction_id' => payment_result[:transaction_id]
          }
        )
      end
      
      # Build response
      response = {
        id: order_id,
        status: 'confirmed',
        customer_id: customer_id,
        total_amount: total_amount,
        items: order_data[:items].map.with_index do |item, index|
          {
            product_id: item[:product_id],
            quantity: item[:quantity],
            unit_price: item[:price],
            total_price: item[:quantity] * item[:price]
          }
        end,
        created_at: Time.now.utc.iso8601,
        updated_at: Time.now.utc.iso8601
      }
      
      # Success event
      RapiTapir::Observability::Tracing.add_event(
        'order.created',
        attributes: {
          'order.id' => order_id,
          'order.status' => 'confirmed'
        }
      )
      
      # Success log
      RapiTapir::Observability::Logging.info(
        "Order created successfully",
        customer_id: customer_id,
        order_id: order_id,
        total_amount: total_amount,
        item_count: item_count,
        tenant_id: tenant_id
      )
      
      response
      
    rescue ValidationError => e
      RapiTapir::Observability::Tracing.record_exception(e)
      RapiTapir::Observability::Logging.log_error(
        e,
        customer_id: customer_id,
        operation: 'order_validation',
        tenant_id: tenant_id
      )
      raise
      
    rescue PaymentError => e
      RapiTapir::Observability::Tracing.record_exception(e)
      RapiTapir::Observability::Logging.log_error(
        e,
        customer_id: customer_id,
        operation: 'payment_processing',
        tenant_id: tenant_id,
        total_amount: total_amount
      )
      raise
      
    rescue => e
      RapiTapir::Observability::Tracing.record_exception(e)
      RapiTapir::Observability::Logging.log_error(
        e,
        customer_id: customer_id,
        operation: 'order_creation',
        tenant_id: tenant_id
      )
      raise
    end
  end

# Helper methods for the example
def calculate_total_amount(items)
  items.sum { |item| item[:quantity] * item[:price] }
end

def validate_order(order_data)
  # Simulation of order validation
  raise ValidationError, "Invalid customer ID" if order_data[:customer_id].nil?
  raise ValidationError, "No items in order" if order_data[:items].empty?
  
  order_data[:items].each do |item|
    raise ValidationError, "Invalid item quantity" if item[:quantity] <= 0
    raise ValidationError, "Invalid item price" if item[:price] <= 0
  end
end

def process_payment(payment_method, amount)
  # Simulation of payment processing
  case payment_method[:type]
  when 'credit_card'
    # Simulate potential payment failure
    raise PaymentError, "Credit card declined" if amount > 10000
    
    {
      status: 'success',
      transaction_id: SecureRandom.hex(16)
    }
  when 'paypal'
    {
      status: 'success',
      transaction_id: "PP_#{SecureRandom.hex(12)}"
    }
  when 'bank_transfer'
    {
      status: 'pending',
      transaction_id: "BT_#{SecureRandom.hex(12)}"
    }
  else
    raise PaymentError, "Unsupported payment method"
  end
end

# Custom exception classes
class ValidationError < StandardError; end
class PaymentError < StandardError; end

# Rack application with observability
class OrderApp
  def call(env)
    # Route to our endpoints
    request = Rack::Request.new(env)
    
    case request.path_info
    when '/orders'
      if request.request_method == 'POST'
        create_order_endpoint.call(env)
      else
        [405, { 'Content-Type' => 'text/plain' }, ['Method Not Allowed']]
      end
    else
      [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
    end
  end
end

# Build Rack app with observability middleware
app = Rack::Builder.new do
  # Add observability middleware
  use RapiTapir::Observability::RackMiddleware
  
  # Your application
  run OrderApp.new
end

puts "Advanced observability example configured!"
puts "Available endpoints:"
puts "- POST /orders (create order with full observability)"
puts "- GET /health (comprehensive health checks)"
puts "- GET /metrics (detailed Prometheus metrics)"
puts ""
puts "Example request:"
puts "curl -X POST http://localhost:9292/orders \\"
puts "  -H 'Content-Type: application/json' \\"
puts "  -H 'Authorization: Bearer your-jwt-token' \\"
puts "  -H 'X-Tenant-ID: 123e4567-e89b-12d3-a456-426614174000' \\"
puts "  -d '{"
puts "    \"customer_id\": \"123e4567-e89b-12d3-a456-426614174000\","
puts "    \"items\": ["
puts "      {"
puts "        \"product_id\": \"123e4567-e89b-12d3-a456-426614174001\","
puts "        \"quantity\": 2,"
puts "        \"price\": 29.99"
puts "      }"
puts "    ],"
puts "    \"shipping_address\": {"
puts "      \"street\": \"123 Main St\","
puts "      \"city\": \"Anytown\","
puts "      \"state\": \"CA\","
puts "      \"zip_code\": \"12345\","
puts "      \"country\": \"US\""
puts "    },"
puts "    \"payment_method\": {"
puts "      \"type\": \"credit_card\","
puts "      \"details\": {}"
puts "    }"
puts "  }'"
puts ""
puts "To run: rackup -p 9292"
