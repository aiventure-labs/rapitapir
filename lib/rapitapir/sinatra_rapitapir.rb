# frozen_string_literal: true

require 'sinatra/base'
require_relative 'sinatra/extension'

module RapiTapir
  # SinatraRapiTapir - A clean base class for RapiTapir APIs
  #
  # This class provides the most ergonomic way to create RapiTapir APIs:
  #
  # class MyAPI < RapiTapir::SinatraRapiTapir
  #   rapitapir do
  #     info(title: 'My API', version: '1.0.0')
  #     development_defaults!
  #   end
  #
  #   endpoint(
  #     GET('/hello').ok(string_response).build
  #   ) { { message: 'Hello!' } }
  # end
  #
  # Features automatically included:
  # - Enhanced HTTP verb DSL (GET, POST, PUT, etc.)
  # - RapiTapir extension with all features
  # - Clean inheritance-based setup
  class SinatraRapiTapir < ::Sinatra::Base
    # Automatically register the RapiTapir extension
    register RapiTapir::Sinatra::Extension

    # Include a helpful message for developers
    configure :development do
      puts '🚀 Using RapiTapir::SinatraRapiTapir base class'
      puts '✨ Enhanced HTTP verb DSL automatically available'
      puts '🔧 Extension features: health checks, CORS, docs, and more'
    end
  end
end

# Also make it available at the top level for convenience
SinatraRapiTapir = RapiTapir::SinatraRapiTapir
