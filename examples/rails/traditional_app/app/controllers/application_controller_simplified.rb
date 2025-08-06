# frozen_string_literal: true

class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  include RapiTapir::Server::Rails::DocumentationHelpers
  
  rapitapir do
    # Enable development features (automatic docs, etc.)
    development_defaults! if Rails.env.development?
    
    # Global error handling
    error_out(json_body(error: T.string, details: T.string.optional), 500)
    error_out(json_body(error: T.string), 401)
    error_out(json_body(error: T.string), 403)
    error_out(json_body(error: T.string), 404)
    error_out(json_body(error: T.string, errors: T.array(T.string).optional), 422)
    
    # Health check endpoint - no separate controller needed!
    GET('/health')
      .out(json_body(
        status: T.string,
        timestamp: T.string,
        version: T.string,
        environment: T.string,
        database: T.string,
        services: T.hash(redis: T.string)
      ))
      .summary("Health check")
      .description("Check API and service health")
      .tag("System")
  end
  
  def health_check
    {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      environment: Rails.env,
      database: database_status,
      services: {
        redis: redis_status
      }
    }
  end
  
  protected
  
  # Helper method for standardized error responses
  def render_error(message, status, details: nil, errors: nil)
    payload = { error: message }
    payload[:details] = details if details
    payload[:errors] = errors if errors
    
    render json: payload, status: status
  end
  
  # Helper for pagination metadata
  def pagination_metadata(collection, page, per_page)
    total = collection.respond_to?(:count) ? collection.count : collection.size
    {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: (total.to_f / per_page).ceil,
      has_next: page < (total.to_f / per_page).ceil,
      has_prev: page > 1
    }
  end
  
  private
  
  def database_status
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue => e
    Rails.logger.error "Database check failed: #{e.message}"
    'disconnected'
  end
  
  def redis_status
    # Example Redis check - uncomment if using Redis
    # Redis.current.ping == 'PONG' ? 'connected' : 'disconnected'
    'not_configured'
  rescue => e
    Rails.logger.error "Redis check failed: #{e.message}"
    'disconnected'
  end
end
