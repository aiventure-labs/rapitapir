# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def check
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      environment: Rails.env,
      database: database_status,
      services: services_status
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
  
  def services_status
    {
      redis: redis_status,
      # Add other service checks here
    }
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
