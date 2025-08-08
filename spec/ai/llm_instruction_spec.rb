# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/ai/llm_instruction'
require 'tmpdir'

RSpec.describe RapiTapir::AI::LLMInstruction::Generator do
  include RapiTapir::DSL

  let(:endpoint) do
    RapiTapir.post('/orders/:id')
             .path_param(:id, :integer)
             .query(:verbose, :boolean, required: false)
             .json_body(RapiTapir::Types.hash({
               'customer' => RapiTapir::Types.string(min_length: 3),
               'items' => RapiTapir::Types.array(RapiTapir::Types.hash({
                 'sku' => RapiTapir::Types.string,
                 'qty' => RapiTapir::Types.integer(minimum: 1)
               }))
             }))
             .ok(RapiTapir::Types.hash({
               'id' => RapiTapir::Types.integer,
               'status' => RapiTapir::Types.string
             }))
             .unprocessable_entity(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }))
             .summary('Create or update an order')
             .llm_instruction(purpose: :validation, fields: :all)
             .build
  end

  let(:generator) { described_class.new([endpoint]) }

  describe '#generate_all_instructions' do
    it 'generates structured instructions for llm-enabled endpoints' do
      data = generator.generate_all_instructions

      expect(data[:meta][:generator]).to include('RapiTapir LLM Instruction Generator')
      expect(data[:meta][:total_instructions]).to eq(1)

      instruction = data[:instructions].first
      expect(instruction[:method]).to eq('POST')
      expect(instruction[:path]).to eq('/orders/:id')
      expect(instruction[:purpose]).to eq(:validation)
      expect(instruction[:instruction]).to include('You are a data validation assistant')

      # schema context must include inputs, outputs, and errors
      schema_ctx = instruction[:schema_context]
      expect(schema_ctx[:inputs].keys).to include(:id, :verbose, :body)
      expect(schema_ctx[:outputs].keys).to include(:json)
      expect(schema_ctx[:errors].keys).to include(422)

  # endpoint_id is normalized
  expect(instruction[:endpoint_id]).to include('post__orders__id')
    end

    it 'raises on unsupported purpose' do
      bad_ep = RapiTapir.get('/ping')
                       .llm_instruction(purpose: :made_up, fields: :all)
                       .build
      gen = described_class.new([bad_ep])

      expect { gen.generate_all_instructions }.to raise_error(ArgumentError, /Unsupported purpose/)
    end
  end
end

RSpec.describe RapiTapir::AI::LLMInstruction::Exporter do
  describe 'export formats' do
    let(:instructions) do
      {
        meta: { generator: 'x', generated_at: 'now', total_instructions: 1 },
        instructions: [
          {
            endpoint_id: 'get__users',
            method: 'GET',
            path: '/users',
            purpose: :documentation,
            instruction: 'Doc text',
            schema_context: { inputs: {}, outputs: {}, errors: {} },
            metadata: { summary: 'List users' }
          }
        ]
      }
    end

    let(:exporter) { described_class.new(instructions) }

    it 'exports JSON and YAML' do
      json = exporter.to_json
      yaml = exporter.to_yaml
      expect(json).to include('"instructions"')
      expect(yaml).to include('instructions:')
    end

    it 'exports Markdown' do
      md = exporter.to_markdown
      expect(md).to include('# LLM Instructions')
      expect(md).to include('## GET /users')
      expect(md).to include('Doc text')
    end

    it 'writes prompt files to a directory' do
      Dir.mktmpdir do |dir|
        msg = exporter.to_prompt_files(dir)
        expect(msg).to include('Exported 1 prompt files')
        files = Dir[File.join(dir, '*')]
        expect(files.size).to eq(1)
        content = File.read(files.first)
        expect(content).to include('Doc text')
      end
    end
  end
end
