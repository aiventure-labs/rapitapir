# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Schema do
  describe '.define' do
    it 'creates a schema with fields' do
      schema = RapiTapir::Schema.define do
        field :name, :string
        field :age, :integer
        field :email, :email, required: false
      end

      expect(schema).to be_a(RapiTapir::Types::Object)
      expect(schema.fields.keys).to contain_exactly(:name, :age, :email)
    end

    it 'supports complex nested types' do
      schema = RapiTapir::Schema.define do
        field :id, :uuid
        field :user, { name: :string, age: :integer }
        field :tags, [:string]
      end

      expect(schema.fields[:id]).to be_a(RapiTapir::Types::UUID)
      expect(schema.fields[:user]).to be_a(RapiTapir::Types::Object)
      expect(schema.fields[:tags]).to be_a(RapiTapir::Types::Array)
    end
  end

  describe '.from_definition' do
    it 'creates types from symbols' do
      type = RapiTapir::Schema.from_definition(:string)
      expect(type).to be_a(RapiTapir::Types::String)
    end

    it 'creates object types from hashes' do
      type = RapiTapir::Schema.from_definition({ name: :string, age: :integer })
      expect(type).to be_a(RapiTapir::Types::Object)
      expect(type.fields.keys).to contain_exactly(:name, :age)
    end

    it 'creates array types from arrays' do
      type = RapiTapir::Schema.from_definition([:string])
      expect(type).to be_a(RapiTapir::Types::Array)
      expect(type.item_type).to be_a(RapiTapir::Types::String)
    end
  end

  describe '.validate!' do
    let(:schema) do
      RapiTapir::Schema.define do
        field :name, :string
        field :age, :integer
      end
    end

    it 'validates valid data' do
      data = { name: 'John', age: 30 }
      expect { RapiTapir::Schema.validate!(data, schema) }.not_to raise_error
    end

    it 'raises error for invalid data' do
      data = { name: 'John', age: 'thirty' }
      expect { RapiTapir::Schema.validate!(data, schema) }.to raise_error(RapiTapir::Schema::ValidationError)
    end
  end

  describe '.validate' do
    let(:schema) do
      RapiTapir::Schema.define do
        field :name, :string
        field :age, :integer
      end
    end

    it 'returns validation result for valid data' do
      data = { name: 'John', age: 30 }
      result = RapiTapir::Schema.validate(data, schema)
      expect(result[:valid]).to be true
    end

    it 'returns validation result for invalid data' do
      data = { name: 'John', age: 'thirty' }
      result = RapiTapir::Schema.validate(data, schema)
      expect(result[:valid]).to be false
      expect(result[:errors]).not_to be_empty
    end
  end

  describe '.coerce' do
    let(:schema) do
      RapiTapir::Schema.define do
        field :id, :integer
        field :name, :string
      end
    end

    it 'coerces data to proper types' do
      data = { 'id' => '123', 'name' => 'John' }
      result = RapiTapir::Schema.coerce(data, schema)
      expect(result).to eq({ id: 123, name: 'John' })
    end
  end
end
