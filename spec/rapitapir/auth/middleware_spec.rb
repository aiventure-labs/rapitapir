# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Auth::Middleware do
  let(:app) { double('App') }

  describe RapiTapir::Auth::Middleware::AuthenticationMiddleware do
    let(:bearer_scheme) { instance_double(RapiTapir::Auth::Schemes::BearerToken) }
    let(:auth_schemes) { { bearer: bearer_scheme } }
    let(:middleware) { described_class.new(app, auth_schemes) }
    let(:env) { { 'HTTP_AUTHORIZATION' => 'Bearer token123' } }

    describe '#call' do
      it 'authenticates request and stores context' do
        user_context = RapiTapir::Auth::Context.new(user: { id: 123 })

        expect(bearer_scheme).to receive(:authenticate).and_return(user_context)
        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        result = middleware.call(env)

        expect(result).to eq([200, {}, ['OK']])
      end

      it 'creates empty context when authentication fails' do
        expect(bearer_scheme).to receive(:authenticate).and_return(nil)
        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        result = middleware.call(env)

        expect(result).to eq([200, {}, ['OK']])
      end

      it 'stores context during request processing' do
        user_context = RapiTapir::Auth::Context.new(user: { id: 123 })
        stored_context = nil

        expect(bearer_scheme).to receive(:authenticate).and_return(user_context)
        expect(app).to receive(:call) do |_env|
          stored_context = RapiTapir::Auth::ContextStore.current
          [200, {}, ['OK']]
        end

        middleware.call(env)

        expect(stored_context).to eq(user_context)
      end
    end
  end

  describe RapiTapir::Auth::Middleware::AuthorizationMiddleware do
    let(:middleware) { described_class.new(app, required_scopes: %w[read write]) }
    let(:env) { {} }

    before do
      allow(RapiTapir::Auth::ContextStore).to receive(:current).and_return(context)
    end

    describe '#call' do
      context 'when user is not authenticated' do
        let(:context) { RapiTapir::Auth::Context.new }

        it 'returns 401 Unauthorized' do
          result = middleware.call(env)

          expect(result[0]).to eq(401)
          expect(result[1]['Content-Type']).to eq('application/json')
          body = JSON.parse(result[2].first)
          expect(body['error']).to eq('Unauthorized')
        end
      end

      context 'when user is authenticated but lacks required scopes' do
        let(:context) { RapiTapir::Auth::Context.new(user: { id: 123 }, scopes: ['read']) }

        it 'returns 403 Forbidden' do
          result = middleware.call(env)

          expect(result[0]).to eq(403)
          expect(result[1]['Content-Type']).to eq('application/json')
          body = JSON.parse(result[2].first)
          expect(body['error']).to eq('Forbidden')
        end
      end

      context 'when user has all required scopes' do
        let(:context) { RapiTapir::Auth::Context.new(user: { id: 123 }, scopes: %w[read write admin]) }

        it 'allows the request to proceed' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'when require_all is false' do
        let(:middleware) { described_class.new(app, required_scopes: %w[read admin], require_all: false) }
        let(:context) { RapiTapir::Auth::Context.new(user: { id: 123 }, scopes: ['read']) }

        it 'allows the request if user has any required scope' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'when no scopes are required' do
        let(:middleware) { described_class.new(app, required_scopes: []) }
        let(:context) { RapiTapir::Auth::Context.new(user: { id: 123 }) }

        it 'allows authenticated users regardless of scopes' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end
      end
    end
  end

  describe RapiTapir::Auth::Middleware::RateLimitingMiddleware do
    let(:storage) { instance_double(described_class::MemoryStorage) }
    let(:middleware) { described_class.new(app, requests_per_minute: 2, storage: storage) }
    let(:env) { { 'REMOTE_ADDR' => '127.0.0.1' } }

    describe '#call' do
      context 'when rate limit is not exceeded' do
        before do
          allow(storage).to receive(:get).and_return(1)
          allow(storage).to receive(:increment)
        end

        it 'allows the request to proceed' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end

        it 'records the request' do
          allow(app).to receive(:call).and_return([200, {}, ['OK']])

          expect(storage).to receive(:increment).twice # minute and hour keys

          middleware.call(env)
        end
      end

      context 'when rate limit is exceeded' do
        before do
          allow(storage).to receive(:get).and_return(5) # exceeds limit of 2
        end

        it 'returns 429 Too Many Requests' do
          result = middleware.call(env)

          expect(result[0]).to eq(429)
          expect(result[1]['Content-Type']).to eq('application/json')
          expect(result[1]['Retry-After']).to eq('60')
          body = JSON.parse(result[2].first)
          expect(body['error']).to eq('Rate Limit Exceeded')
        end
      end
    end

    describe described_class::MemoryStorage do
      let(:storage) { described_class.new }

      describe '#get' do
        it 'returns nil for non-existent key' do
          expect(storage.get('nonexistent')).to be_nil
        end

        it 'returns value for existing key' do
          storage.increment('test_key')
          expect(storage.get('test_key')).to eq(1)
        end

        it 'returns nil for expired key' do
          storage.increment('test_key', expires_in: -1)
          expect(storage.get('test_key')).to be_nil
        end
      end

      describe '#increment' do
        it 'increments value for new key' do
          storage.increment('test_key')
          expect(storage.get('test_key')).to eq(1)
        end

        it 'increments value for existing key' do
          storage.increment('test_key')
          storage.increment('test_key')
          expect(storage.get('test_key')).to eq(2)
        end

        it 'sets expiration time' do
          storage.increment('test_key', expires_in: 60)
          expect(storage.get('test_key')).to eq(1)
        end
      end
    end
  end

  describe RapiTapir::Auth::Middleware::CorsMiddleware do
    let(:middleware) { described_class.new(app) }

    describe '#call' do
      context 'when handling preflight request' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'OPTIONS',
            'HTTP_ORIGIN' => 'https://example.com'
          }
        end

        it 'returns CORS preflight response' do
          result = middleware.call(env)

          expect(result[0]).to eq(200)
          expect(result[1]['Access-Control-Allow-Origin']).to eq('*')
          expect(result[1]['Access-Control-Allow-Methods']).to include('GET', 'POST')
          expect(result[2]).to eq([''])
        end
      end

      context 'when handling regular request' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'GET',
            'HTTP_ORIGIN' => 'https://example.com'
          }
        end

        it 'adds CORS headers to response' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result[0]).to eq(200)
          expect(result[1]['Access-Control-Allow-Origin']).to eq('*')
        end
      end

      context 'with specific allowed origins' do
        let(:middleware) { described_class.new(app, allowed_origins: ['https://allowed.com']) }
        let(:env) do
          {
            'REQUEST_METHOD' => 'GET',
            'HTTP_ORIGIN' => 'https://allowed.com'
          }
        end

        it 'allows specific origin' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result[1]['Access-Control-Allow-Origin']).to eq('https://allowed.com')
        end
      end

      context 'with wildcard origins' do
        let(:middleware) { described_class.new(app, allowed_origins: ['https://*.example.com']) }
        let(:env) do
          {
            'REQUEST_METHOD' => 'GET',
            'HTTP_ORIGIN' => 'https://api.example.com'
          }
        end

        it 'allows wildcard matching origins' do
          expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

          result = middleware.call(env)

          expect(result[1]['Access-Control-Allow-Origin']).to eq('https://api.example.com')
        end
      end
    end
  end

  describe RapiTapir::Auth::Middleware::SecurityHeadersMiddleware do
    let(:middleware) { described_class.new(app) }
    let(:env) { {} }

    describe '#call' do
      it 'adds security headers to response' do
        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        result = middleware.call(env)

        headers = result[1]
        expect(headers['X-Content-Type-Options']).to eq('nosniff')
        expect(headers['X-Frame-Options']).to eq('DENY')
        expect(headers['X-XSS-Protection']).to eq('1; mode=block')
        expect(headers['Strict-Transport-Security']).to include('max-age=31536000')
        expect(headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
      end

      it 'does not override existing headers' do
        existing_headers = { 'X-Frame-Options' => 'SAMEORIGIN' }
        expect(app).to receive(:call).with(env).and_return([200, existing_headers, ['OK']])

        result = middleware.call(env)

        expect(result[1]['X-Frame-Options']).to eq('SAMEORIGIN')
      end

      it 'allows custom security headers' do
        custom_middleware = described_class.new(
          app,
          headers: { 'Custom-Header' => 'custom-value' }
        )

        expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])

        result = custom_middleware.call(env)

        expect(result[1]['Custom-Header']).to eq('custom-value')
      end
    end
  end
end
