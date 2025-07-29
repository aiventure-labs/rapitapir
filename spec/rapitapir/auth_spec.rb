# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Auth do
  describe '.bearer_token' do
    it 'creates a bearer token scheme' do
      scheme = described_class.bearer_token(:my_bearer, token_validator: proc { |token| { user: { id: token } } })
      
      expect(scheme).to be_a(RapiTapir::Auth::Schemes::BearerToken)
      expect(scheme.name).to eq(:my_bearer)
    end
  end

  describe '.api_key' do
    it 'creates an API key scheme' do
      scheme = described_class.api_key(:my_api_key, header_name: 'X-Custom-Key')
      
      expect(scheme).to be_a(RapiTapir::Auth::Schemes::ApiKey)
      expect(scheme.name).to eq(:my_api_key)
    end
  end

  describe '.basic_auth' do
    it 'creates a basic auth scheme' do
      scheme = described_class.basic_auth(:my_basic, realm: 'Custom Realm')
      
      expect(scheme).to be_a(RapiTapir::Auth::Schemes::BasicAuth)
      expect(scheme.name).to eq(:my_basic)
    end
  end

  describe '.oauth2' do
    it 'creates an OAuth2 scheme' do
      scheme = described_class.oauth2(:my_oauth, client_id: 'client123')
      
      expect(scheme).to be_a(RapiTapir::Auth::Schemes::OAuth2)
      expect(scheme.name).to eq(:my_oauth)
    end
  end

  describe '.jwt' do
    it 'creates a JWT scheme' do
      scheme = described_class.jwt(:my_jwt, secret: 'secret123')
      
      expect(scheme).to be_a(RapiTapir::Auth::Schemes::JWT)
      expect(scheme.name).to eq(:my_jwt)
    end
  end

  describe 'middleware factory methods' do
    describe '.authentication_middleware' do
      it 'creates authentication middleware' do
        middleware = described_class.authentication_middleware({ bearer: 'scheme' })
        
        expect(middleware).to be_a(RapiTapir::Auth::Middleware::AuthenticationMiddleware)
      end
    end

    describe '.authorization_middleware' do
      it 'creates authorization middleware' do
        middleware = described_class.authorization_middleware(required_scopes: ['read'])
        
        expect(middleware).to be_a(RapiTapir::Auth::Middleware::AuthorizationMiddleware)
      end
    end

    describe '.rate_limiting_middleware' do
      it 'creates rate limiting middleware' do
        middleware = described_class.rate_limiting_middleware(requests_per_minute: 100)
        
        expect(middleware).to be_a(RapiTapir::Auth::Middleware::RateLimitingMiddleware)
      end
    end

    describe '.cors_middleware' do
      it 'creates CORS middleware' do
        middleware = described_class.cors_middleware(allowed_origins: ['*'])
        
        expect(middleware).to be_a(RapiTapir::Auth::Middleware::CorsMiddleware)
      end
    end

    describe '.security_headers_middleware' do
      it 'creates security headers middleware' do
        middleware = described_class.security_headers_middleware
        
        expect(middleware).to be_a(RapiTapir::Auth::Middleware::SecurityHeadersMiddleware)
      end
    end
  end

  describe 'context access methods' do
    let(:context) { RapiTapir::Auth::Context.new(user: { id: 123 }, scopes: ['read']) }

    before do
      allow(RapiTapir::Auth::ContextStore).to receive(:current).and_return(context)
    end

    describe '.current_context' do
      it 'returns the current context' do
        expect(described_class.current_context).to eq(context)
      end
    end

    describe '.current_user' do
      it 'returns the current user' do
        expect(described_class.current_user).to eq({ id: 123 })
      end
    end

    describe '.authenticated?' do
      it 'returns true when authenticated' do
        expect(described_class.authenticated?).to be true
      end

      it 'returns false when not authenticated' do
        allow(RapiTapir::Auth::ContextStore).to receive(:current).and_return(nil)
        expect(described_class.authenticated?).to be false
      end
    end

    describe '.has_scope?' do
      it 'returns true for existing scope' do
        expect(described_class.has_scope?('read')).to be true
      end

      it 'returns false for non-existing scope' do
        expect(described_class.has_scope?('write')).to be false
      end

      it 'returns false when no context' do
        allow(RapiTapir::Auth::ContextStore).to receive(:current).and_return(nil)
        expect(described_class.has_scope?('read')).to be false
      end
    end
  end

  describe 'configuration' do
    after do
      # Reset configuration after each test
      described_class.configuration = nil
    end

    describe '.configure' do
      it 'yields configuration object' do
        described_class.configure do |config|
          expect(config).to be_a(RapiTapir::Auth::Configuration)
        end
      end

      it 'sets configuration' do
        described_class.configure do |config|
          config.oauth2.client_id = 'test_client'
        end

        expect(described_class.config.oauth2.client_id).to eq('test_client')
      end
    end

    describe '.config' do
      it 'returns configuration instance' do
        expect(described_class.config).to be_a(RapiTapir::Auth::Configuration)
      end

      it 'returns same instance on subsequent calls' do
        config1 = described_class.config
        config2 = described_class.config
        
        expect(config1).to be(config2)
      end
    end
  end
end
