# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/observability'

RSpec.describe RapiTapir::Observability::Configuration do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'initializes with default configurations' do
      expect(config.metrics).to be_a(RapiTapir::Observability::Configuration::MetricsConfig)
      expect(config.tracing).to be_a(RapiTapir::Observability::Configuration::TracingConfig)
      expect(config.logging).to be_a(RapiTapir::Observability::Configuration::LoggingConfig)
      expect(config.health_check).to be_a(RapiTapir::Observability::Configuration::HealthCheckConfig)
    end
  end

  describe 'MetricsConfig' do
    let(:metrics_config) { config.metrics }

    it 'has default values' do
      expect(metrics_config.enabled).to be false
      expect(metrics_config.provider).to eq :prometheus
      expect(metrics_config.namespace).to eq 'rapitapir'
      expect(metrics_config.custom_labels).to eq({})
    end

    describe '#enable_prometheus' do
      it 'enables metrics with custom namespace and labels' do
        metrics_config.enable_prometheus(namespace: 'my_app', labels: { env: 'test' })

        expect(metrics_config.enabled).to be true
        expect(metrics_config.provider).to eq :prometheus
        expect(metrics_config.namespace).to eq 'my_app'
        expect(metrics_config.custom_labels).to eq({ env: 'test' })
      end
    end

    describe '#disable' do
      it 'disables metrics' do
        metrics_config.enable_prometheus
        metrics_config.disable

        expect(metrics_config.enabled).to be false
      end
    end
  end

  describe 'TracingConfig' do
    let(:tracing_config) { config.tracing }

    it 'has default values' do
      expect(tracing_config.enabled).to be false
      expect(tracing_config.provider).to eq :opentelemetry
      expect(tracing_config.service_name).to eq 'rapitapir-api'
      expect(tracing_config.service_version).to eq RapiTapir::VERSION
    end

    describe '#enable_opentelemetry' do
      it 'enables tracing with custom service info' do
        tracing_config.enable_opentelemetry(service_name: 'my-service', service_version: '2.0.0')

        expect(tracing_config.enabled).to be true
        expect(tracing_config.provider).to eq :opentelemetry
        expect(tracing_config.service_name).to eq 'my-service'
        expect(tracing_config.service_version).to eq '2.0.0'
      end
    end
  end

  describe 'LoggingConfig' do
    let(:logging_config) { config.logging }

    it 'has default values' do
      expect(logging_config.enabled).to be true
      expect(logging_config.structured).to be false
      expect(logging_config.level).to eq :info
      expect(logging_config.format).to eq :text
      expect(logging_config.fields).to include(:timestamp, :level, :message, :request_id)
    end

    describe '#enable_structured' do
      it 'enables structured logging with custom fields' do
        custom_fields = %i[timestamp level message custom_field]
        logging_config.enable_structured(level: :debug, fields: custom_fields)

        expect(logging_config.enabled).to be true
        expect(logging_config.structured).to be true
        expect(logging_config.level).to eq :debug
        expect(logging_config.fields).to eq custom_fields
      end
    end
  end

  describe 'HealthCheckConfig' do
    let(:health_check_config) { config.health_check }

    it 'has default values' do
      expect(health_check_config.enabled).to be false
      expect(health_check_config.endpoint).to eq '/health'
      expect(health_check_config.checks).to be_empty
    end

    describe '#enable' do
      it 'enables health checks with custom endpoint' do
        health_check_config.enable(endpoint: '/status')

        expect(health_check_config.enabled).to be true
        expect(health_check_config.endpoint).to eq '/status'
      end
    end

    describe '#add_check' do
      it 'adds a custom health check' do
        check_block = -> { { status: :healthy } }
        health_check_config.add_check(:custom_check, &check_block)

        expect(health_check_config.checks.length).to eq(1)
        expect(health_check_config.checks.first[:name]).to eq :custom_check
        expect(health_check_config.checks.first[:check]).to eq check_block
      end
    end
  end
end
