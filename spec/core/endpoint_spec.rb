# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Core::Endpoint do
  describe '.new' do
    it 'creates an endpoint with default values' do
      endpoint = described_class.new

      expect(endpoint.method).to be_nil
      expect(endpoint.path).to be_nil
      expect(endpoint.inputs).to eq([])
      expect(endpoint.outputs).to eq([])
      expect(endpoint.errors).to eq([])
      expect(endpoint.metadata).to eq({})
    end

    it 'creates an endpoint with provided values' do
      input = RapiTapir::Core::Input.new(kind: :query, name: :test, type: :string)
      output = RapiTapir::Core::Output.new(kind: :json, type: { message: :string })

      endpoint = described_class.new(
        method: :get,
        path: '/test',
        inputs: [input],
        outputs: [output],
        metadata: { description: 'Test endpoint' }
      )

      expect(endpoint.method).to eq(:get)
      expect(endpoint.path).to eq('/test')
      expect(endpoint.inputs).to eq([input])
      expect(endpoint.outputs).to eq([output])
      expect(endpoint.metadata).to eq({ description: 'Test endpoint' })
    end
  end

  describe 'HTTP method shortcuts' do
    %i[get post put patch delete options head].each do |method|
      it "creates a #{method.upcase} endpoint" do
        endpoint = described_class.send(method, '/test')

        expect(endpoint.method).to eq(method)
        expect(endpoint.path).to eq('/test')
      end
    end
  end

  describe '#in' do
    let(:endpoint) { described_class.get('/test') }
    let(:input) { RapiTapir::Core::Input.new(kind: :query, name: :name, type: :string) }

    it 'adds an input to the endpoint' do
      new_endpoint = endpoint.in(input)

      expect(new_endpoint.inputs).to include(input)
      expect(new_endpoint).not_to be(endpoint) # Immutability
    end

    it 'validates the input' do
      invalid_input = double('input')

      expect { endpoint.in(invalid_input) }.to raise_error(ArgumentError)
    end
  end

  describe '#out' do
    let(:endpoint) { described_class.get('/test') }
    let(:output) { RapiTapir::Core::Output.new(kind: :json, type: { message: :string }) }

    it 'adds an output to the endpoint' do
      new_endpoint = endpoint.out(output)

      expect(new_endpoint.outputs).to include(output)
      expect(new_endpoint).not_to be(endpoint) # Immutability
    end

    it 'validates the output' do
      invalid_output = double('output')

      expect { endpoint.out(invalid_output) }.to raise_error(ArgumentError)
    end
  end

  describe '#error_out' do
    let(:endpoint) { described_class.get('/test') }
    let(:output) { RapiTapir::Core::Output.new(kind: :json, type: { error: :string }) }

    it 'adds an error output to the endpoint' do
      new_endpoint = endpoint.error_out(404, output)

      expect(new_endpoint.errors).to include({ code: 404, output: output })
    end

    it 'supports additional options' do
      new_endpoint = endpoint.error_out(400, output, description: 'Bad request')

      expect(new_endpoint.errors.first[:description]).to eq('Bad request')
    end

    it 'validates the status code' do
      expect { endpoint.error_out(999, output) }.to raise_error(ArgumentError)
    end
  end

  describe '#with_metadata' do
    let(:endpoint) { described_class.get('/test') }

    it 'adds metadata to the endpoint' do
      new_endpoint = endpoint.with_metadata(description: 'Test endpoint')

      expect(new_endpoint.metadata[:description]).to eq('Test endpoint')
    end

    it 'merges with existing metadata' do
      endpoint_with_meta = endpoint.with_metadata(description: 'Test')
      new_endpoint = endpoint_with_meta.with_metadata(summary: 'Summary')

      expect(new_endpoint.metadata).to eq({ description: 'Test', summary: 'Summary' })
    end
  end

  describe 'convenience metadata methods' do
    let(:endpoint) { described_class.get('/test') }

    it '#description sets description metadata' do
      new_endpoint = endpoint.description('Test description')

      expect(new_endpoint.metadata[:description]).to eq('Test description')
    end

    it '#summary sets summary metadata' do
      new_endpoint = endpoint.summary('Test summary')

      expect(new_endpoint.metadata[:summary]).to eq('Test summary')
    end

    it '#tag sets tag metadata' do
      new_endpoint = endpoint.tag('users')

      expect(new_endpoint.metadata[:tag]).to eq('users')
    end

    it '#deprecated sets deprecated metadata' do
      new_endpoint = endpoint.deprecated

      expect(new_endpoint.metadata[:deprecated]).to be(true)
    end

    it '#deprecated with false sets deprecated to false' do
      new_endpoint = endpoint.deprecated(false)

      expect(new_endpoint.metadata[:deprecated]).to be(false)
    end
  end

  describe '#validate!' do
    let(:input) { RapiTapir::Core::Input.new(kind: :query, name: :name, type: :string) }
    let(:output) { RapiTapir::Core::Output.new(kind: :json, type: { message: :string }) }
    let(:endpoint) { described_class.get('/test').in(input).out(output) }

    context 'with valid inputs' do
      it 'validates successfully' do
        expect { endpoint.validate!({ name: 'test' }) }.not_to raise_error
      end
    end

    context 'with invalid inputs' do
      it 'raises TypeError for wrong input type' do
        expect { endpoint.validate!({ name: 123 }) }.to raise_error(TypeError, /Invalid type for input 'name'/)
      end
    end

    context 'with valid outputs' do
      it 'validates successfully' do
        expect { endpoint.validate!({}, { message: 'hello' }) }.not_to raise_error
      end
    end

    context 'with invalid outputs' do
      it 'raises TypeError for wrong output type' do
        expect { endpoint.validate!({}, { message: 123 }) }.to raise_error(TypeError, /Invalid output hash/)
      end
    end

    context 'with empty output hash' do
      it 'skips output validation' do
        expect { endpoint.validate!({ name: 'test' }, {}) }.not_to raise_error
      end
    end
  end

  describe '#to_h' do
    let(:input) { RapiTapir::Core::Input.new(kind: :query, name: :name, type: :string) }
    let(:output) { RapiTapir::Core::Output.new(kind: :json, type: { message: :string }) }
    let(:endpoint) do
      described_class.get('/test')
                     .in(input)
                     .out(output)
                     .error_out(404, output)
                     .description('Test endpoint')
    end

    it 'returns a hash representation' do
      hash = endpoint.to_h

      expect(hash[:method]).to eq(:get)
      expect(hash[:path]).to eq('/test')
      expect(hash[:inputs]).to be_an(Array)
      expect(hash[:outputs]).to be_an(Array)
      expect(hash[:errors]).to be_an(Array)
      expect(hash[:metadata]).to eq({ description: 'Test endpoint' })
    end
  end
end
