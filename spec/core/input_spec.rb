# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Core::Input do
  describe '.new' do
    it 'creates an input with valid parameters' do
      input = described_class.new(kind: :query, name: :test, type: :string)

      expect(input.kind).to eq(:query)
      expect(input.name).to eq(:test)
      expect(input.type).to eq(:string)
      expect(input.options).to eq({})
    end

    it 'validates kind parameter' do
      expect { described_class.new(kind: :invalid, name: :test, type: :string) }
        .to raise_error(ArgumentError, /Invalid kind/)
    end

    it 'validates name parameter' do
      expect { described_class.new(kind: :query, name: nil, type: :string) }
        .to raise_error(ArgumentError, /name cannot be nil/)
    end

    it 'validates type parameter' do
      expect { described_class.new(kind: :query, name: :test, type: :invalid) }
        .to raise_error(ArgumentError, /Invalid type/)
    end

    it 'accepts hash types' do
      expect { described_class.new(kind: :body, name: :data, type: { name: :string }) }
        .not_to raise_error
    end

    it 'accepts class types' do
      expect { described_class.new(kind: :body, name: :data, type: String) }
        .not_to raise_error
    end
  end

  describe '#required?' do
    it 'returns true by default' do
      input = described_class.new(kind: :query, name: :test, type: :string)

      expect(input.required?).to be(true)
    end

    it 'returns false when optional' do
      input = described_class.new(kind: :query, name: :test, type: :string, options: { optional: true })

      expect(input.required?).to be(false)
    end
  end

  describe '#optional?' do
    it 'returns false by default' do
      input = described_class.new(kind: :query, name: :test, type: :string)

      expect(input.optional?).to be(false)
    end

    it 'returns true when optional' do
      input = described_class.new(kind: :query, name: :test, type: :string, options: { optional: true })

      expect(input.optional?).to be(true)
    end
  end

  describe '#valid_type?' do
    context 'with string type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :string) }

      it 'validates string values' do
        expect(input.valid_type?('hello')).to be(true)
        expect(input.valid_type?(123)).to be(false)
      end
    end

    context 'with integer type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :integer) }

      it 'validates integer values' do
        expect(input.valid_type?(123)).to be(true)
        expect(input.valid_type?('123')).to be(false)
      end
    end

    context 'with float type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :float) }

      it 'validates float and integer values' do
        expect(input.valid_type?(123.45)).to be(true)
        expect(input.valid_type?(123)).to be(true)
        expect(input.valid_type?('123.45')).to be(false)
      end
    end

    context 'with boolean type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :boolean) }

      it 'validates boolean values' do
        expect(input.valid_type?(true)).to be(true)
        expect(input.valid_type?(false)).to be(true)
        expect(input.valid_type?('true')).to be(false)
      end
    end

    context 'with date type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :date) }

      it 'validates date values and strings' do
        expect(input.valid_type?(Date.today)).to be(true)
        expect(input.valid_type?('2023-01-01')).to be(true)
        expect(input.valid_type?('invalid-date')).to be(false)
      end
    end

    context 'with hash type' do
      let(:input) { described_class.new(kind: :body, name: :data, type: { name: :string, age: :integer }) }

      it 'validates hash schemas' do
        expect(input.valid_type?({ name: 'John', age: 30 })).to be(true)
        expect(input.valid_type?({ name: 'John', age: '30' })).to be(false)
      end
    end

    context 'with optional input' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :string, options: { optional: true }) }

      it 'allows nil values' do
        expect(input.valid_type?(nil)).to be(true)
        expect(input.valid_type?('hello')).to be(true)
      end
    end
  end

  describe '#coerce' do
    context 'with string type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :string) }

      it 'coerces values to string' do
        expect(input.coerce(123)).to eq('123')
        expect(input.coerce('hello')).to eq('hello')
      end
    end

    context 'with integer type' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :integer) }

      it 'coerces values to integer' do
        expect(input.coerce('123')).to eq(123)
        expect(input.coerce(123.45)).to eq(123)
      end

      it 'raises error for invalid values' do
        expect { input.coerce('invalid') }.to raise_error(TypeError)
      end
    end

    context 'with optional input' do
      let(:input) { described_class.new(kind: :query, name: :test, type: :string, options: { optional: true }) }

      it 'returns nil for nil values' do
        expect(input.coerce(nil)).to be_nil
      end
    end
  end

  describe '#to_h' do
    let(:input) { described_class.new(kind: :query, name: :test, type: :string, options: { optional: true }) }

    it 'returns a hash representation' do
      hash = input.to_h

      expect(hash[:kind]).to eq(:query)
      expect(hash[:name]).to eq(:test)
      expect(hash[:type]).to eq(:string)
      expect(hash[:options]).to eq({ optional: true })
      expect(hash[:required]).to be(false)
    end
  end
end
