# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/openapi/schema_generator'

RSpec.describe 'RapiTapir::OpenAPI::SchemaGenerator error/edge cases' do
  it 'includes enhanced error responses with description and schema' do
    ep = RapiTapir.get('/err')
                  .bad_request(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }), description: 'Bad input')
                  .build

    gen = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: [ep])
    schema = gen.generate
    op = schema[:paths]['/err']['get']
    expect(op[:responses]['400'][:description]).to eq('Bad input')
    expect(op[:responses]['400'][:content]['application/json'][:schema]).to be_a(Hash)
  end

  it 'adds default 200 response when no outputs or errors defined' do
    ep = RapiTapir.get('/noop').build

    gen = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: [ep])
    schema = gen.generate
    op = schema[:paths]['/noop']['get']
    expect(op[:responses]).to have_key('200')
    expect(op[:responses]['200'][:description]).to eq('Successful response')
  end

  it 'uses xml content-type for xml outputs' do
    # Build a legacy output with :xml kind via Core::Output
    output = RapiTapir::Core::Output.new(kind: :xml, type: :string)
    ep = RapiTapir::Core::Endpoint.get('/xml').out(output)

    gen = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: [ep])
    schema = gen.generate
    op = schema[:paths]['/xml']['get']
    # 200 response should have application/xml content
    expect(op[:responses]['200'][:content]).to have_key('application/xml')
  end
end
