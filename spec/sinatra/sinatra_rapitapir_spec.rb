# frozen_string_literal: true

require 'spec_helper'
require 'sinatra/base'

# Only run these tests if Sinatra is available
if defined?(Sinatra)
  require_relative '../../lib/rapitapir/sinatra_rapitapir'

  RSpec.describe RapiTapir::SinatraRapiTapir do
    let(:test_app) do
      Class.new(RapiTapir::SinatraRapiTapir) do
        rapitapir do
          info(title: 'Test API', version: '1.0.0')
        end
      end
    end

    describe 'inheritance and setup' do
      it 'inherits from Sinatra::Base' do
        expect(RapiTapir::SinatraRapiTapir.superclass).to eq(Sinatra::Base)
      end

      it 'automatically registers RapiTapir extension' do
        expect(test_app.extensions).to include(RapiTapir::Sinatra::Extension)
      end

      it 'has enhanced HTTP verb DSL methods available' do
        %w[GET POST PUT PATCH DELETE HEAD OPTIONS].each do |verb|
          expect(test_app).to respond_to(verb)
        end
      end

      it 'creates functional endpoints using enhanced DSL' do
        expect do
          test_app.class_eval do
            endpoint(
              GET('/test')
                .summary('Test endpoint')
                .ok(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string }))
                .build
            ) { { message: 'Hello from SinatraRapiTapir!' } }
          end
        end.not_to raise_error
      end
    end

    describe 'top-level constant' do
      it 'makes SinatraRapiTapir available at top level' do
        expect(defined?(SinatraRapiTapir)).to be_truthy
        expect(SinatraRapiTapir).to eq(RapiTapir::SinatraRapiTapir)
      end

      it 'allows clean inheritance syntax' do
        clean_app = Class.new(SinatraRapiTapir) do
          rapitapir do
            info(title: 'Clean API', version: '1.0.0')
          end
        end

        expect(clean_app.superclass).to eq(SinatraRapiTapir)
        expect(clean_app.extensions).to include(RapiTapir::Sinatra::Extension)
      end
    end

    describe 'functionality' do
      it 'maintains all RapiTapir features' do
        app = Class.new(RapiTapir::SinatraRapiTapir) do
          rapitapir do
            info(title: 'Feature Test API', version: '1.0.0')
            development_defaults!
          end

          endpoint(
            GET('/test')
              .summary('Test endpoint')
              .ok(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string }))
              .build
          ) { { message: 'Test successful' } }
        end

        # Should have configuration
        expect(app.settings.rapitapir_config).to be_a(RapiTapir::Sinatra::Configuration)

        # Should have endpoints
        expect(app.settings.rapitapir_endpoints).not_to be_empty

        # Should have development defaults applied
        health_endpoint = app.settings.rapitapir_endpoints.find { |ep| ep[:endpoint].path == '/health' }
        expect(health_endpoint).not_to be_nil
      end

      it 'works with enhanced HTTP verb methods' do
        %w[GET POST PUT PATCH DELETE HEAD OPTIONS].each do |verb|
          builder = test_app.send(verb, "/#{verb.downcase}")

          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(verb.downcase.to_sym)
          expect(builder.instance_variable_get(:@path)).to eq("/#{verb.downcase}")
        end
      end

      it 'maintains backward compatibility with RapiTapir.get syntax' do
        expect do
          test_app.class_eval do
            endpoint(
              RapiTapir.get('/legacy')
                .summary('Legacy syntax')
                .ok(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string }))
                .build
            ) { { message: 'Legacy works!' } }
          end
        end.not_to raise_error
      end
    end

    describe 'comparison with manual setup' do
      let(:manual_app) do
        Class.new(Sinatra::Base) do
          register RapiTapir::Sinatra::Extension

          rapitapir do
            info(title: 'Manual API', version: '1.0.0')
          end
        end
      end

      it 'provides equivalent functionality to manual extension registration' do
        # Both should have the extension registered
        expect(test_app.extensions).to include(RapiTapir::Sinatra::Extension)
        expect(manual_app.extensions).to include(RapiTapir::Sinatra::Extension)

        # Both should have enhanced DSL
        %w[GET POST PUT PATCH DELETE HEAD OPTIONS].each do |verb|
          expect(test_app).to respond_to(verb)
          expect(manual_app).to respond_to(verb)
        end

        # Both should be able to create endpoints
        expect do
          test_app.class_eval do
            endpoint(GET('/auto').ok(RapiTapir::Types.string).build) { 'auto' }
          end
          manual_app.class_eval do
            endpoint(GET('/manual').ok(RapiTapir::Types.string).build) { 'manual' }
          end
        end.not_to raise_error
      end
    end
  end
else
  RSpec.describe 'SinatraRapiTapir (Sinatra not available)' do
    it 'skips tests when Sinatra is not available' do
      skip 'Sinatra not available in this environment'
    end
  end
end
