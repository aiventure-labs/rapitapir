# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Core::Output do
  describe '.new' do
    it 'creates an output with valid parameters' do
      output = described_class.new(kind: :json, type: { message: :string })

      expect(output.kind).to eq(:json)
      expect(output.type).to eq({ message: :string })
      expect(output.options).to eq({})
    end

    it 'validates kind parameter' do
      expect { described_class.new(kind: :invalid, type: :string) }
        .to raise_error(ArgumentError, /Invalid kind/)
    end

    it 'validates status type' do
      expect { described_class.new(kind: :status, type: 999) }
        .to raise_error(ArgumentError, /Status type must be an integer between 100-599/)
    end

    it 'accepts valid status codes' do
      expect { described_class.new(kind: :status, type: 200) }.not_to raise_error
      expect { described_class.new(kind: :status, type: 404) }.not_to raise_error
      expect { described_class.new(kind: :status, type: 500) }.not_to raise_error
    end
  end

  describe '#valid_type?' do
    context 'with json kind and hash type' do
      let(:output) { described_class.new(kind: :json, type: { message: :string, count: :integer }) }

      it 'validates hash schemas' do
        expect(output.valid_type?({ message: 'hello', count: 5 })).to be(true)
        expect(output.valid_type?({ message: 'hello', count: '5' })).to be(false)
        expect(output.valid_type?({ message: 123, count: 5 })).to be(false)
      end
    end

    context 'with status kind' do
      let(:output) { described_class.new(kind: :status, type: 200) }

      it 'accepts any value for status' do
        expect(output.valid_type?(200)).to be(true)
        expect(output.valid_type?('OK')).to be(true)
      end
    end

    context 'with primitive types' do
      let(:string_output) { described_class.new(kind: :json, type: :string) }
      let(:integer_output) { described_class.new(kind: :json, type: :integer) }

      it 'validates string types' do
        expect(string_output.valid_type?('hello')).to be(true)
        expect(string_output.valid_type?(123)).to be(false)
      end

      it 'validates integer types' do
        expect(integer_output.valid_type?(123)).to be(true)
        expect(integer_output.valid_type?(123.45)).to be(true) # Floats are accepted for integers
        expect(integer_output.valid_type?('123')).to be(false)
      end
    end
  end

  describe '#serialize' do
    context 'with json kind' do
      let(:output) { described_class.new(kind: :json, type: { message: :string }) }

      it 'serializes hash to JSON' do
        result = output.serialize({ message: 'hello' })
        expect(result).to eq('{"message":"hello"}')
      end

      it 'serializes string as-is' do
        result = output.serialize('{"message":"hello"}')
        expect(result).to eq('{"message":"hello"}')
      end

      it 'handles serialization errors' do
        circular = {}
        circular[:self] = circular

        expect { output.serialize(circular) }.to raise_error(TypeError, /Cannot serialize value to JSON/)
      end
    end

    context 'with xml kind' do
      let(:output) { described_class.new(kind: :xml, type: { message: :string }) }

      it 'serializes hash to basic XML' do
        result = output.serialize({ message: 'hello' })
        expect(result).to eq('<root><message>hello</message></root>')
      end

      it 'returns string as-is' do
        result = output.serialize('<message>hello</message>')
        expect(result).to eq('<message>hello</message>')
      end
    end

    context 'with status kind' do
      let(:output) { described_class.new(kind: :status, type: 200) }

      it 'converts to integer' do
        expect(output.serialize('200')).to eq(200)
        expect(output.serialize(200.0)).to eq(200)
      end
    end

    context 'with header kind' do
      let(:output) { described_class.new(kind: :header, type: :string) }

      it 'converts to string' do
        expect(output.serialize(123)).to eq('123')
        expect(output.serialize('hello')).to eq('hello')
      end
    end
  end

  describe '#to_h' do
    let(:output) { described_class.new(kind: :json, type: { message: :string }, options: { format: 'pretty' }) }

    it 'returns a hash representation' do
      hash = output.to_h

      expect(hash[:kind]).to eq(:json)
      expect(hash[:type]).to eq({ message: :string })
      expect(hash[:options]).to eq({ format: 'pretty' })
    end
  end
end
