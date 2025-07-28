# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'rapitapir/server/rack_adapter'

RSpec.describe 'Debug RackAdapter JSON parsing' do
  include Rack::Test::Methods

  let(:adapter) { RapiTapir::Server::RackAdapter.new }
  let(:app) { adapter }

  it 'debugs JSON body parsing' do
    endpoint = RapiTapir.post('/debug')
      .json_body(RapiTapir::Types.hash({}))
      .ok(RapiTapir::Types.hash({"received" => RapiTapir::Types.hash({})}))
      .summary('Debug endpoint')
      .build
    
    handler = proc do |inputs|
      puts "Handler received: #{inputs.inspect}"
      puts "Data class: #{inputs[:data].class}"
      puts "Data content: #{inputs[:data]}"
      { received: inputs[:data] }
    end
    
    adapter.register_endpoint(endpoint, handler)
    
    post '/debug', JSON.generate({ test: 'value' }), { 'CONTENT_TYPE' => 'application/json' }
    
    puts "Response status: #{last_response.status}"
    puts "Response body: #{last_response.body}"
    
    expect(last_response.status).to eq(200)
  end
end
