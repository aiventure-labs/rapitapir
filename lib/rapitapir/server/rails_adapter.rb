# frozen_string_literal: true

require_relative 'rails_controller'
require_relative 'rails_adapter_class'

# Load enhanced Rails integration components
require_relative 'rails/controller_base'
require_relative 'rails/configuration'
require_relative 'rails/routes'
require_relative 'rails/resource_builder'
require_relative 'rails/documentation_helpers'

module RapiTapir
  module Server
    # Rails integration module for RapiTapir
    #
    # Provides controller concerns and adapters for seamless integration with Rails applications.
    # Includes the enhanced Rails integration with ControllerBase and auto-routing.
    module Rails
      # Main module that includes both legacy Controller concern and enhanced ControllerBase
      # This maintains backward compatibility while providing the new enhanced features
    end
  end
end
