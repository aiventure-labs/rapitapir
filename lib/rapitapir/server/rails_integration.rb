# frozen_string_literal: true

# Rails integration loader - ensures proper module initialization
# Only loads if Rails and ActiveSupport are available

# First, ensure the module structure exists
module RapiTapir
  module Server
    module Rails
      # Rails integration module for RapiTapir
    end
  end

  # Define a method to load Rails integration when Rails becomes available
  def self.load_rails_integration!
    return if @rails_integration_loaded
    return unless defined?(Rails) && defined?(ActiveSupport)

    # Remove fallback ControllerBase if it exists
    RapiTapir::Server::Rails.send(:remove_const, :ControllerBase) if RapiTapir::Server::Rails.const_defined?(:ControllerBase)

    # Load Rails integration components in the correct order
    require_relative 'rails_controller'
    require_relative 'rails_adapter_class'
    require_relative 'rails/configuration'
    require_relative 'rails/routes'
    require_relative 'rails/resource_builder'
    require_relative 'rails/documentation_helpers'
    require_relative 'rails/controller_base'

    # Create Railtie for Rails integration
    if defined?(Rails::Railtie) && !Object.const_defined?(:RapiTapirRailtie)
      Object.const_set(:RapiTapirRailtie, Class.new(Rails::Railtie) do
        initializer 'rapitapir.extend_routes', after: :initialize_routes do |app|
          app.routes&.extend(RapiTapir::Server::Rails::Routes)
        end
      end)
    end

    @rails_integration_loaded = true
  end
end

# Load immediately if Rails is already available
if defined?(Rails) && defined?(ActiveSupport)
  RapiTapir.load_rails_integration!
else
  # Rails not available - provide minimal fallback
  module RapiTapir
    module Server
      module Rails
        class ControllerBase
          def self.method_missing(method, ...)
            # Try to load Rails integration when accessed
            RapiTapir.load_rails_integration!
            if defined?(RapiTapir::Server::Rails::ControllerBase) && self.class != RapiTapir::Server::Rails::ControllerBase
              return RapiTapir::Server::Rails::ControllerBase.send(method, ...)
            end

            raise NameError,
                  'Rails integration not available. Please ensure Rails is loaded before requiring RapiTapir.'
          end
        end
      end
    end
  end
end
