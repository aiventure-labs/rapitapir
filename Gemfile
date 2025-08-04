# frozen_string_literal: true

source 'https://rubygems.org'

gem 'json', '~> 2.6'
gem 'rack', '~> 3.0'
gem 'webrick', '~> 1.8' # For CLI server functionality
gem 'jwt', '~> 2.7' # For OAuth2 JWT validation
gem 'dotenv', '~> 2.8' # For environment variable management

group :development, :test do
  gem 'puma', '~> 6.0'
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.12'
  gem 'simplecov', '~> 0.22'
  gem 'sinatra', '~> 4.0'
  gem 'webmock', '~> 3.19'
end

gem 'rackup', '~> 2.2'

# OpenTelemetry for observability (Honeycomb.io integration)
gem 'opentelemetry-sdk', '~> 1.3'
gem 'opentelemetry-exporter-otlp', '~> 0.26'
gem 'opentelemetry-instrumentation-all', '~> 0.57'
