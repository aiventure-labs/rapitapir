# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Auth::Schemes do
  describe RapiTapir::Auth::Schemes::BearerToken do
    let(:scheme) { described_class.new(:bearer) }

    describe '#authenticate' do
      let(:request) { double('Request', env: env) }

      context 'when Authorization header is missing' do
        let(:env) { {} }

        it 'returns nil' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end

      context 'when Authorization header is not Bearer' do
        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic dXNlcjpwYXNz' } }

        it 'returns nil' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end

      context 'when Authorization header has Bearer token' do
        let(:env) { { 'HTTP_AUTHORIZATION' => 'Bearer valid_token' } }

        it 'authenticates with valid token' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user).to eq({ id: 'default_user', name: 'Default User' })
          expect(context.scopes).to eq(['read'])
          expect(context.token).to eq('valid_token')
        end

        it 'returns nil for invalid token' do
          env_with_empty_token = { 'HTTP_AUTHORIZATION' => 'Bearer ' }
          request_with_empty_token = double('Request', env: env_with_empty_token)

          expect(scheme.authenticate(request_with_empty_token)).to be_nil
        end
      end
    end

    describe '#challenge' do
      it 'returns Bearer challenge' do
        expect(scheme.challenge).to eq('Bearer realm="API"')
      end

      it 'uses custom realm' do
        scheme = described_class.new(:bearer, realm: 'Custom')
        expect(scheme.challenge).to eq('Bearer realm="Custom"')
      end
    end
  end

  describe RapiTapir::Auth::Schemes::ApiKey do
    let(:scheme) { described_class.new(:api_key) }

    describe '#authenticate' do
      let(:request) { double('Request', env: env, params: params) }
      let(:params) { {} }

      context 'when API key is in header' do
        let(:env) { { 'HTTP_X_API_KEY' => 'valid_key' } }

        it 'authenticates with valid key' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user).to eq({ id: 'api_user', name: 'API User' })
          expect(context.scopes).to eq(['api'])
          expect(context.token).to eq('valid_key')
        end
      end

      context 'when API key is in query parameter' do
        let(:env) { {} }
        let(:params) { { 'api_key' => 'valid_key' } }
        let(:scheme) { described_class.new(:api_key, location: :query) }

        it 'authenticates with valid key' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user).to eq({ id: 'api_user', name: 'API User' })
          expect(context.scopes).to eq(['api'])
          expect(context.token).to eq('valid_key')
        end
      end

      context 'when API key is missing' do
        let(:env) { {} }

        it 'returns nil' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end
    end

    describe '#challenge' do
      it 'returns ApiKey challenge' do
        expect(scheme.challenge).to eq('ApiKey')
      end
    end
  end

  describe RapiTapir::Auth::Schemes::BasicAuth do
    let(:scheme) { described_class.new(:basic) }

    describe '#authenticate' do
      let(:request) { double('Request', env: env) }

      context 'when Authorization header is missing' do
        let(:env) { {} }

        it 'returns nil' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end

      context 'when Authorization header has Basic credentials' do
        let(:credentials) { Base64.encode64('user:pass').strip }
        let(:env) { { 'HTTP_AUTHORIZATION' => "Basic #{credentials}" } }

        it 'authenticates with valid credentials' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user).to eq({ id: 'user', name: 'User' })
          expect(context.scopes).to eq(['basic'])
          expect(context.metadata[:username]).to eq('user')
        end

        it 'returns nil for invalid credentials' do
          empty_credentials = Base64.encode64(':').strip
          env_with_empty_creds = { 'HTTP_AUTHORIZATION' => "Basic #{empty_credentials}" }
          request_with_empty_creds = double('Request', env: env_with_empty_creds)

          expect(scheme.authenticate(request_with_empty_creds)).to be_nil
        end
      end

      context 'when Authorization header has malformed Basic credentials' do
        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic invalid' } }

        it 'returns nil' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end
    end

    describe '#challenge' do
      it 'returns Basic challenge' do
        expect(scheme.challenge).to eq('Basic realm="API"')
      end
    end
  end

  describe RapiTapir::Auth::Schemes::OAuth2 do
    let(:scheme) { described_class.new(:oauth2) }

    describe '#authenticate' do
      let(:request) { double('Request', env: env) }

      context 'when Authorization header has Bearer token' do
        let(:env) { { 'HTTP_AUTHORIZATION' => 'Bearer oauth_token' } }

        it 'authenticates with valid OAuth2 token' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user).to eq({ id: 'oauth_user', name: 'OAuth User' })
          expect(context.scopes).to eq(%w[read write])
          expect(context.metadata[:client_id]).to eq('default_client')
        end
      end
    end

    describe '#challenge' do
      it 'returns Bearer challenge' do
        expect(scheme.challenge).to eq('Bearer realm="API"')
      end
    end
  end

  describe RapiTapir::Auth::Schemes::JWT do
    let(:secret) { 'test_secret' }
    let(:scheme) { described_class.new(:jwt, secret: secret) }

    describe '#authenticate' do
      let(:request) { double('Request', env: env) }

      context 'when Authorization header has valid JWT' do
        let(:payload) { { 'sub' => 'user123', 'scopes' => %w[read write], 'exp' => Time.now.to_i + 3600 } }
        let(:token) { create_jwt_token(payload, secret) }
        let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token}" } }

        it 'authenticates with valid JWT' do
          context = scheme.authenticate(request)

          expect(context).not_to be_nil
          expect(context.user[:id]).to eq('user123')
          expect(context.scopes).to eq(%w[read write])
          expect(context.metadata[:token_type]).to eq('jwt')
        end
      end

      context 'when JWT is expired' do
        let(:payload) { { 'sub' => 'user123', 'exp' => Time.now.to_i - 3600 } }
        let(:token) { create_jwt_token(payload, secret) }
        let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token}" } }

        it 'returns nil for expired token' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end

      context 'when JWT signature is invalid' do
        let(:payload) { { 'sub' => 'user123' } }
        let(:token) { create_jwt_token(payload, 'wrong_secret') }
        let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token}" } }

        it 'returns nil for invalid signature' do
          expect(scheme.authenticate(request)).to be_nil
        end
      end
    end

    describe '#challenge' do
      it 'returns Bearer challenge' do
        expect(scheme.challenge).to eq('Bearer realm="API"')
      end
    end

    private

    def create_jwt_token(payload, secret)
      header = { 'alg' => 'HS256', 'typ' => 'JWT' }

      encoded_header = Base64.urlsafe_encode64(JSON.generate(header)).tr('=', '')
      encoded_payload = Base64.urlsafe_encode64(JSON.generate(payload)).tr('=', '')

      signature = Base64.urlsafe_encode64(
        OpenSSL::HMAC.digest('SHA256', secret, "#{encoded_header}.#{encoded_payload}")
      ).tr('=', '')

      "#{encoded_header}.#{encoded_payload}.#{signature}"
    end
  end
end
