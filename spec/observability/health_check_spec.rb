# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/observability'

RSpec.describe RapiTapir::Observability::HealthCheck do
  after(:each) do
    # Reset the registry between tests
    described_class.instance_variable_set(:@registry, nil)
  end

  describe RapiTapir::Observability::HealthCheck::Check do
    describe '#call' do
      context 'when check returns true' do
        let(:check) { described_class.new(:test_check) { true } }

        it 'returns healthy status' do
          result = check.call
          expect(result[:status]).to eq :healthy
          expect(result[:name]).to eq :test_check
          expect(result[:duration_ms]).to be >= 0
        end
      end

      context 'when check returns false' do
        let(:check) { described_class.new(:test_check) { false } }

        it 'returns unhealthy status' do
          result = check.call
          expect(result[:status]).to eq :unhealthy
          expect(result[:name]).to eq :test_check
        end
      end

      context 'when check returns hash with status' do
        let(:check) { described_class.new(:test_check) { { status: :warning, message: 'Slow response' } } }

        it 'returns the specified status and message' do
          result = check.call
          expect(result[:status]).to eq :warning
          expect(result[:message]).to eq 'Slow response'
        end
      end

      context 'when check raises an exception' do
        let(:check) { described_class.new(:test_check) { raise StandardError, 'Check failed' } }

        it 'returns unhealthy status with error message' do
          result = check.call
          expect(result[:status]).to eq :unhealthy
          expect(result[:message]).to include 'StandardError: Check failed'
        end
      end
    end
  end

  describe RapiTapir::Observability::HealthCheck::Registry do
    let(:registry) { described_class.new }

    describe '#register' do
      it 'registers a new health check' do
        registry.register(:database) { true }
        expect(registry.check_names).to include :database
      end
    end

    describe '#run_all' do
      before do
        registry.register(:check1) { true }
        registry.register(:check2) { { status: :healthy, message: 'OK' } }
        registry.register(:check3) { false }
      end

      it 'runs all checks and returns overall status' do
        result = registry.run_all
        
        expect(result[:status]).to eq :unhealthy # Because check3 fails
        expect(result[:service]).to eq 'rapitapir'
        expect(result[:version]).to eq RapiTapir::VERSION
        expect(result[:checks].length).to eq(6) # 3 custom + 3 default
      end
    end

    describe '#run_check' do
      before do
        registry.register(:test_check) { { status: :healthy, message: 'Test OK' } }
      end

      it 'runs a specific check by name' do
        result = registry.run_check(:test_check)
        expect(result[:status]).to eq :healthy
        expect(result[:message]).to eq 'Test OK'
      end

      it 'returns error for non-existent check' do
        result = registry.run_check(:non_existent)
        expect(result[:error]).to include "Check 'non_existent' not found"
      end
    end

    describe 'default checks' do
      it 'includes ruby runtime check' do
        expect(registry.check_names).to include :ruby_runtime
      end

      it 'includes memory usage check' do
        expect(registry.check_names).to include :memory_usage
      end

      it 'includes thread count check' do
        expect(registry.check_names).to include :thread_count
      end
    end
  end

  describe RapiTapir::Observability::HealthCheck::Endpoint do
    let(:registry) { RapiTapir::Observability::HealthCheck::Registry.new }
    let(:endpoint) { described_class.new(registry, '/health') }

    before do
      registry.register(:test_check) { true }
    end

    describe '#call' do
      context 'when requesting overall health' do
        let(:env) { { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/health' } }

        it 'returns overall health status' do
          status, headers, body = endpoint.call(env)
          
          expect(status).to eq 200
          expect(headers['Content-Type']).to eq 'application/json'
          
          response = JSON.parse(body.first)
          expect(response['status']).to eq 'healthy'
          expect(response['checks']).to be_an Array
        end
      end

      context 'when requesting individual check' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'GET',
            'PATH_INFO' => '/health/check',
            'QUERY_STRING' => 'name=test_check'
          }
        end

        it 'returns individual check result' do
          status, _headers, body = endpoint.call(env)
          
          expect(status).to eq 200
          response = JSON.parse(body.first)
          expect(response['status']).to eq 'healthy'
        end
      end

      context 'when requesting checks list' do
        let(:env) { { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/health/checks' } }

        it 'returns list of available checks' do
          status, _headers, body = endpoint.call(env)
          
          expect(status).to eq 200
          response = JSON.parse(body.first)
          expect(response['available_checks']).to be_an Array
          expect(response['total']).to be > 0
        end
      end

      context 'when requesting non-existent path' do
        let(:env) { { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/unknown' } }

        it 'returns 404' do
          status, _, _ = endpoint.call(env)
          expect(status).to eq 404
        end
      end
    end
  end

  describe 'module methods' do
    before do
      RapiTapir::Observability.configure do |config|
        config.health_check.enable
      end
    end

    describe '.configure' do
      it 'configures health check with endpoint' do
        described_class.configure(endpoint: '/status')
        expect(described_class.instance_variable_get(:@endpoint_path)).to eq '/status'
      end
    end

    describe '.register' do
      it 'registers a health check' do
        described_class.register(:custom_check) { true }
        expect(described_class.registry.check_names).to include :custom_check
      end
    end

    describe '.run_all' do
      it 'runs all health checks when enabled' do
        result = described_class.run_all
        expect(result[:status]).to eq(:healthy).or eq(:unhealthy)
        expect(result[:checks]).to be_an Array
      end
    end

    context 'when health checks are disabled' do
      before do
        RapiTapir::Observability.configure do |config|
          config.health_check.enabled = false
        end
      end

      it 'returns error message' do
        result = described_class.run_all
        expect(result[:error]).to eq 'Health checks disabled'
      end
    end
  end
end
