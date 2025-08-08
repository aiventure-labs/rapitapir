# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/openapi/schema_generator'

RSpec.describe RapiTapir::OpenAPI::SchemaGenerator do
  describe 'type mapping and response/status edges' do
    it 'maps date and datetime to string with formats' do
      gen = described_class.new(endpoints: [])
      date_schema = gen.send(:type_to_schema, :date)
      dt_schema = gen.send(:type_to_schema, :datetime)

      expect(date_schema).to eq(type: 'string', format: 'date')
      expect(dt_schema).to eq(type: 'string', format: 'date-time')
    end

    it 'maps RapiTapir array type and Ruby array types appropriately' do
      gen = described_class.new(endpoints: [])

      rt_array = RapiTapir::Types.array(RapiTapir::Types.string)
      schema = gen.send(:type_to_schema, rt_array)
      expect(schema).to eq(type: 'array', items: { type: 'string' })

  ruby_single = [Integer]
  schema2 = gen.send(:type_to_schema, ruby_single)
  # Current implementation defaults to string for Ruby class mappings
  expect(schema2).to eq(type: 'array', items: { type: 'string' })

      ruby_multi = [Integer, String]
      schema3 = gen.send(:type_to_schema, ruby_multi)
      expect(schema3).to eq(type: 'array', items: { type: 'string' })
    end

    it 'generates header parameter with required=false when optional' do
      ep = RapiTapir.get('/h')
                    .header(:'X-Token', RapiTapir::Types.string, required: false)
                    .build

      schema = described_class.new(endpoints: [ep]).generate
      op = schema[:paths]['/h']['get']
      header_param = op[:parameters].find { |p| p[:in] == 'header' }
      expect(header_param[:name]).to eq('X-Token')
      expect(header_param[:required]).to be(false)
    end

    it 'generates 201 status when Core::Output status is present' do
      ep = RapiTapir::Core::Endpoint.post('/create').out(RapiTapir::Core::Output.new(kind: :status, type: 201))
      schema = described_class.new(endpoints: [ep]).generate
      op = schema[:paths]['/create']['post']
      expect(op[:responses]).to have_key('201')
      expect(op[:responses]['201'][:description]).to eq('Successful response')
    end

    it 'builds enhanced error responses (422) with provided schema and description' do
      ep = RapiTapir.get('/legacy')
                    .unprocessable_entity(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }),
                                          description: 'Legacy validation error')
                    .build

      schema = described_class.new(endpoints: [ep]).generate
      op = schema[:paths]['/legacy']['get']
      expect(op[:responses]).to have_key('422')
      resp = op[:responses]['422']
      expect(resp[:description]).to eq('Legacy validation error')
      expect(resp[:content]['application/json'][:schema]).to be_a(Hash)
    end
  end
end
