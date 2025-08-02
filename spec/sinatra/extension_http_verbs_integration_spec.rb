# frozen_string_literal: true

require 'spec_helper'
require 'sinatra/base'
require_relative '../../lib/rapitapir/sinatra/extension'

RSpec.describe 'RapiTapir Sinatra Extension Automatic HTTP Verbs DSL' do
  let(:test_app) do
    Class.new(Sinatra::Base) do
      register RapiTapir::Sinatra::Extension

      rapitapir do
        info(title: 'Test API', version: '1.0.0')
        development_defaults!
      end
    end
  end

  describe 'automatic HTTP verb DSL inclusion' do
    it 'includes GET method automatically' do
      expect(test_app).to respond_to(:GET)
    end

    it 'includes POST method automatically' do
      expect(test_app).to respond_to(:POST)
    end

    it 'includes PUT method automatically' do
      expect(test_app).to respond_to(:PUT)
    end

    it 'includes PATCH method automatically' do
      expect(test_app).to respond_to(:PATCH)
    end

    it 'includes DELETE method automatically' do
      expect(test_app).to respond_to(:DELETE)
    end

    it 'includes HEAD method automatically' do
      expect(test_app).to respond_to(:HEAD)
    end

    it 'includes OPTIONS method automatically' do
      expect(test_app).to respond_to(:OPTIONS)
    end

    it 'creates functional endpoints using enhanced DSL' do
      # This should work without any manual includes/extends
      expect do
        test_app.class_eval do
          endpoint(
            GET('/test')
              .summary('Test endpoint')
              .ok(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string }))
              .build
          ) { { message: 'Hello from enhanced DSL!' } }
        end
      end.not_to raise_error
    end

    it 'produces the same results as RapiTapir.get' do
      get_builder = test_app.GET('/api/test')
      rapitapir_builder = RapiTapir.get('/api/test')

      expect(get_builder.class).to eq(rapitapir_builder.class)
      expect(get_builder.instance_variable_get(:@method)).to eq(rapitapir_builder.instance_variable_get(:@method))
      expect(get_builder.instance_variable_get(:@path)).to eq(rapitapir_builder.instance_variable_get(:@path))
    end

    it 'works with all HTTP verbs' do
      verbs = %w[GET POST PUT PATCH DELETE HEAD OPTIONS]

      verbs.each do |verb|
        builder = test_app.send(verb, "/#{verb.downcase}")

        expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
        expect(builder.instance_variable_get(:@method)).to eq(verb.downcase.to_sym)
        expect(builder.instance_variable_get(:@path)).to eq("/#{verb.downcase}")
      end
    end
  end

  describe 'integration with existing Sinatra extension features' do
    it 'works alongside health check auto-generation' do
      app = Class.new(Sinatra::Base) do
        register RapiTapir::Sinatra::Extension

        rapitapir do
          info(title: 'Integration Test API', version: '1.0.0')
          development_defaults!
        end

        # Using enhanced DSL alongside automatic health check
        endpoint(
          GET('/status')
            .summary('Custom status endpoint')
            .ok(RapiTapir::Types.hash({ 'status' => RapiTapir::Types.string }))
            .build
        ) { { status: 'operational' } }
      end

      # Should have both automatic health check and custom endpoint
      config = app.settings.rapitapir_config
      expect(config.health_check_enabled?).to be true
      expect(app.settings.rapitapir_endpoints.length).to be >= 1
    end

    it 'maintains backward compatibility with RapiTapir.get syntax' do
      app = Class.new(Sinatra::Base) do
        register RapiTapir::Sinatra::Extension

        rapitapir do
          info(title: 'Backward Compatibility Test', version: '1.0.0')
        end

        # Both should work in the same app
        endpoint(
          RapiTapir.get('/old-style')
            .summary('Old style endpoint')
            .ok(RapiTapir::Types.hash({ 'style' => RapiTapir::Types.string }))
            .build
        ) { { style: 'old' } }

        endpoint(
          GET('/new-style')
            .summary('New style endpoint')
            .ok(RapiTapir::Types.hash({ 'style' => RapiTapir::Types.string }))
            .build
        ) { { style: 'new' } }
      end

      expect(app.settings.rapitapir_endpoints.length).to eq(2)
    end
  end
end
