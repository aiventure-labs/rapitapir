# frozen_string_literal: true

require 'rspec'
require 'rack/test'
require 'json'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

# Helper methods for testing serverless functions
module ServerlessTestHelpers
  def parse_json_response
    JSON.parse(last_response.body)
  end

  def expect_json_response(expected_keys = [])
    expect(last_response.content_type).to include('application/json')
    response_body = parse_json_response
    expected_keys.each do |key|
      expect(response_body).to have_key(key.to_s)
    end
    response_body
  end

  def mock_aws_context(request_id: 'test-request-123')
    OpenStruct.new(
      aws_request_id: request_id,
      function_name: 'test-function',
      function_version: '$LATEST',
      memory_limit_in_mb: '512'
    )
  end

  def mock_gcp_request(method: 'GET', path: '/', body: nil, headers: {})
    request = double('request')
    allow(request).to receive(:request_method).and_return(method)
    allow(request).to receive(:path).and_return(path)
    allow(request).to receive(:query_string).and_return('')
    allow(request).to receive(:body).and_return(StringIO.new(body || ''))
    allow(request).to receive(:content_type).and_return(headers['Content-Type'])
    allow(request).to receive(:headers).and_return(headers)
    allow(request).to receive(:host).and_return('localhost')
    allow(request).to receive(:port).and_return(8080)
    request
  end

  def mock_azure_context(invocation_id: 'test-invocation-123')
    {
      invocation_id: invocation_id,
      function_name: 'test-function',
      function_directory: '/tmp'
    }
  end

  def mock_vercel_request(method: 'GET', url: 'https://localhost/', body: nil, headers: {})
    request = double('request')
    allow(request).to receive(:method).and_return(method)
    allow(request).to receive(:url).and_return(url)
    allow(request).to receive(:body).and_return(body)
    allow(request).to receive(:headers).and_return(headers)
    request
  end
end

RSpec.configure do |config|
  config.include ServerlessTestHelpers
end
