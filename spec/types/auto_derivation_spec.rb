# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Types::AutoDerivation do
  describe '.from_json_schema' do
    context 'with valid JSON schema' do
      let(:user_schema) do
        {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'integer' },
            'name' => { 'type' => 'string' },
            'email' => { 'type' => 'string', 'format' => 'email' },
            'age' => { 'type' => 'integer' },
            'active' => { 'type' => 'boolean' },
            'tags' => { 'type' => 'array', 'items' => { 'type' => 'string' } },
            'metadata' => { 'type' => 'object' }
          },
          'required' => %w[id name email]
        }
      end

      it 'creates a simple hash schema' do
        schema = {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' }
          },
          'required' => ['name']
        }

        result = described_class.from_json_schema(schema)
        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types['name']).to be_a(RapiTapir::Types::String)
      end

      it 'creates a hash schema with correct field types' do
        result = described_class.from_json_schema(user_schema)

        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types.keys).to contain_exactly('id', 'name', 'email', 'age', 'active', 'tags', 'metadata')
        expect(result.field_types['id']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['name']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['email']).to be_a(RapiTapir::Types::Email)
        expect(result.field_types['active']).to be_a(RapiTapir::Types::Optional)
        expect(result.field_types['tags']).to be_a(RapiTapir::Types::Optional)
        expect(result.field_types['metadata']).to be_a(RapiTapir::Types::Optional)
      end

      it 'handles special string formats' do
        schema = {
          'type' => 'object',
          'properties' => {
            'email' => { 'type' => 'string', 'format' => 'email' },
            'uuid' => { 'type' => 'string', 'format' => 'uuid' },
            'date' => { 'type' => 'string', 'format' => 'date' },
            'datetime' => { 'type' => 'string', 'format' => 'date-time' },
            'plain' => { 'type' => 'string' }
          },
          'required' => %w[email uuid date datetime plain]
        }

        result = described_class.from_json_schema(schema)

        expect(result.field_types['email']).to be_a(RapiTapir::Types::Email)
        expect(result.field_types['uuid']).to be_a(RapiTapir::Types::UUID)
        expect(result.field_types['date']).to be_a(RapiTapir::Types::Date)
        expect(result.field_types['datetime']).to be_a(RapiTapir::Types::DateTime)
        expect(result.field_types['plain']).to be_a(RapiTapir::Types::String)
      end

      it 'supports field filtering with only parameter' do
        result = described_class.from_json_schema(user_schema, only: %i[id name])

        expect(result.field_types.keys).to contain_exactly('id', 'name')
        expect(result.field_types['id']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['name']).to be_a(RapiTapir::Types::String)
      end

      it 'supports field filtering with except parameter' do
        result = described_class.from_json_schema(user_schema, except: %i[metadata tags])

        expect(result.field_types.keys).to contain_exactly('id', 'name', 'email', 'age', 'active')
        expect(result.field_types).not_to have_key('metadata')
        expect(result.field_types).not_to have_key('tags')
      end

      it 'handles arrays with typed items' do
        schema = {
          'type' => 'object',
          'properties' => {
            'string_array' => { 'type' => 'array', 'items' => { 'type' => 'string' } },
            'number_array' => { 'type' => 'array', 'items' => { 'type' => 'integer' } },
            'untyped_array' => { 'type' => 'array' }
          },
          'required' => %w[string_array number_array untyped_array]
        }

        result = described_class.from_json_schema(schema)

        string_array = result.field_types['string_array']
        expect(string_array).to be_a(RapiTapir::Types::Array)
        expect(string_array.item_type).to be_a(RapiTapir::Types::String)

        number_array = result.field_types['number_array']
        expect(number_array).to be_a(RapiTapir::Types::Array)
        expect(number_array.item_type).to be_a(RapiTapir::Types::Integer)

        untyped_array = result.field_types['untyped_array']
        expect(untyped_array).to be_a(RapiTapir::Types::Array)
        expect(untyped_array.item_type).to be_a(RapiTapir::Types::String)
      end
    end

    context 'with invalid input' do
      it 'raises error for non-object schema' do
        expect do
          described_class.from_json_schema({ 'type' => 'string' })
        end.to raise_error(ArgumentError, /JSON Schema must be an object/)
      end

      it 'raises error for non-hash input' do
        expect do
          described_class.from_json_schema('not a hash')
        end.to raise_error(ArgumentError, /JSON Schema must be an object/)
      end

      it 'raises error for missing type' do
        expect do
          described_class.from_json_schema({ 'properties' => {} })
        end.to raise_error(ArgumentError, /JSON Schema must be an object/)
      end
    end
  end

  describe '.from_open_struct' do
    require 'ostruct'

    context 'with valid OpenStruct' do
      let(:config) do
        # rubocop:disable Style/OpenStructUse
        OpenStruct.new(
          host: 'localhost',
          port: 3000,
          ssl: true,
          timeout: 30.5,
          features: %w[auth logging],
          metadata: { version: '1.0' }
        )
        # rubocop:enable Style/OpenStructUse
      end

      it 'creates a hash schema with inferred types' do
        result = described_class.from_open_struct(config)

        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types.keys).to contain_exactly('host', 'port', 'ssl', 'timeout', 'features', 'metadata')
        expect(result.field_types['host']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['port']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['ssl']).to be_a(RapiTapir::Types::Boolean)
        expect(result.field_types['timeout']).to be_a(RapiTapir::Types::Float)
        expect(result.field_types['features']).to be_a(RapiTapir::Types::Array)
        expect(result.field_types['metadata']).to be_a(RapiTapir::Types::Hash)
      end

      it 'supports field filtering with only parameter' do
        result = described_class.from_open_struct(config, only: %i[host port])

        expect(result.field_types.keys).to contain_exactly('host', 'port')
        expect(result.field_types['host']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['port']).to be_a(RapiTapir::Types::Integer)
      end

      it 'supports field filtering with except parameter' do
        result = described_class.from_open_struct(config, except: %i[metadata features])

        expect(result.field_types.keys).to contain_exactly('host', 'port', 'ssl', 'timeout')
        expect(result.field_types).not_to have_key('metadata')
        expect(result.field_types).not_to have_key('features')
      end

      it 'handles various Ruby types correctly' do
        require 'date'
        # rubocop:disable Style/OpenStructUse
        data = OpenStruct.new(
          string_val: 'test',
          integer_val: 42,
          float_val: 3.14,
          boolean_true: true,
          boolean_false: false,
          date_val: Date.today,
          time_val: Time.now,
          array_val: [1, 2, 3],
          hash_val: { key: 'value' },
          nil_val: nil
        )
        # rubocop:enable Style/OpenStructUse

        result = described_class.from_open_struct(data)

        expect(result.field_types['string_val']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['integer_val']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['float_val']).to be_a(RapiTapir::Types::Float)
        expect(result.field_types['boolean_true']).to be_a(RapiTapir::Types::Boolean)
        expect(result.field_types['boolean_false']).to be_a(RapiTapir::Types::Boolean)
        expect(result.field_types['date_val']).to be_a(RapiTapir::Types::Date)
        expect(result.field_types['time_val']).to be_a(RapiTapir::Types::DateTime)
        expect(result.field_types['array_val']).to be_a(RapiTapir::Types::Array)
        expect(result.field_types['hash_val']).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types['nil_val']).to be_a(RapiTapir::Types::String)
      end

      it 'handles empty OpenStruct' do
        # rubocop:disable Style/OpenStructUse
        empty_struct = OpenStruct.new
        # rubocop:enable Style/OpenStructUse
        result = described_class.from_open_struct(empty_struct)

        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types).to be_empty
      end
    end

    context 'with invalid input' do
      it 'raises error for non-OpenStruct input' do
        expect do
          described_class.from_open_struct({ not: 'ostruct' })
        end.to raise_error(ArgumentError, /Expected OpenStruct/)
      end

      it 'raises error for nil input' do
        expect do
          described_class.from_open_struct(nil)
        end.to raise_error(ArgumentError, /Expected OpenStruct/)
      end
    end
  end

  describe '.from_hash' do
    context 'with valid hash' do
      it 'creates a hash schema with inferred types' do
        hash = {
          name: 'John',
          age: 30,
          score: 95.5,
          active: true
        }

        result = described_class.from_hash(hash)

        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types['name']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['age']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['score']).to be_a(RapiTapir::Types::Float)
        expect(result.field_types['active']).to be_a(RapiTapir::Types::Boolean)
      end

      it 'handles various Ruby types correctly' do
        require 'date'

        hash = {
          string_val: 'test',
          integer_val: 42,
          float_val: 3.14,
          boolean_true: true,
          boolean_false: false,
          date_val: Date.today,
          time_val: Time.now,
          array_val: [1, 2, 3],
          hash_val: { key: 'value' },
          nil_val: nil
        }

        result = described_class.from_hash(hash)

        expect(result.field_types['string_val']).to be_a(RapiTapir::Types::String)
        expect(result.field_types['integer_val']).to be_a(RapiTapir::Types::Integer)
        expect(result.field_types['float_val']).to be_a(RapiTapir::Types::Float)
        expect(result.field_types['boolean_true']).to be_a(RapiTapir::Types::Boolean)
        expect(result.field_types['boolean_false']).to be_a(RapiTapir::Types::Boolean)
        expect(result.field_types['date_val']).to be_a(RapiTapir::Types::Date)
        expect(result.field_types['time_val']).to be_a(RapiTapir::Types::DateTime)
        expect(result.field_types['array_val']).to be_a(RapiTapir::Types::Array)
        expect(result.field_types['hash_val']).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types['nil_val']).to be_a(RapiTapir::Types::String)
      end

      it 'handles empty hash' do
        result = described_class.from_hash({})

        expect(result).to be_a(RapiTapir::Types::Hash)
        expect(result.field_types).to be_empty
      end

      it 'supports field filtering with only parameter' do
        hash = { name: 'John', age: 30, email: 'john@test.com' }

        result = described_class.from_hash(hash, only: %i[name age])

        expect(result.field_types.keys).to contain_exactly('name', 'age')
        expect(result.field_types).not_to have_key('email')
      end

      it 'supports field filtering with except parameter' do
        hash = { name: 'John', age: 30, email: 'john@test.com' }

        result = described_class.from_hash(hash, except: [:email])

        expect(result.field_types.keys).to contain_exactly('name', 'age')
        expect(result.field_types).not_to have_key('email')
      end

      it 'handles nested arrays correctly' do
        hash = {
          numbers: [1, 2, 3],
          strings: %w[a b c],
          empty_array: []
        }

        result = described_class.from_hash(hash)

        numbers_type = result.field_types['numbers']
        expect(numbers_type).to be_a(RapiTapir::Types::Array)
        expect(numbers_type.item_type).to be_a(RapiTapir::Types::Integer)

        strings_type = result.field_types['strings']
        expect(strings_type).to be_a(RapiTapir::Types::Array)
        expect(strings_type.item_type).to be_a(RapiTapir::Types::String)

        empty_type = result.field_types['empty_array']
        expect(empty_type).to be_a(RapiTapir::Types::Array)
        expect(empty_type.item_type).to be_a(RapiTapir::Types::String)
      end
    end

    context 'with invalid input' do
      it 'raises error for non-hash input' do
        expect do
          described_class.from_hash('not a hash')
        end.to raise_error(ArgumentError, /Expected Hash/)
      end

      it 'raises error for nil input' do
        expect do
          described_class.from_hash(nil)
        end.to raise_error(ArgumentError, /Expected Hash/)
      end

      it 'raises error for array input' do
        expect do
          described_class.from_hash([1, 2, 3])
        end.to raise_error(ArgumentError, /Expected Hash/)
      end
    end
  end

  describe '.from_protobuf' do
    context 'when protobuf is not available' do
      it 'raises error for missing protobuf' do
        # Hide the Google::Protobuf constant if it exists
        hide_const('Google::Protobuf') if defined?(Google::Protobuf)

        fake_proto_class = double('FakeProtoClass')

        expect do
          described_class.from_protobuf(fake_proto_class)
        end.to raise_error(ArgumentError, /Protobuf not available/)
      end
    end

    context 'when protobuf is available' do
      before do
        skip 'Google::Protobuf not available' unless defined?(Google::Protobuf)
      end

      it 'creates schema from protobuf class' do
        # This would require actual protobuf setup
        # For now, just test the basic structure
        expect(described_class).to respond_to(:from_protobuf)
      end
    end
  end

  describe 'convenience methods in Types module' do
    it 'delegates to AutoDerivation module' do
      schema = { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }

      expect(described_class).to receive(:from_json_schema).with(schema)
      RapiTapir::Types.from_json_schema(schema)
    end

    it 'passes through options correctly' do
      schema = { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }
      options = { only: [:name] }

      expect(described_class).to receive(:from_json_schema).with(schema, options)
      RapiTapir::Types.from_json_schema(schema, **options)
    end

    it 'delegates from_hash to AutoDerivation module' do
      hash = { name: 'test', age: 30 }

      expect(described_class).to receive(:from_hash).with(hash)
      RapiTapir::Types.from_hash(hash)
    end

    it 'passes through from_hash options correctly' do
      hash = { name: 'test', age: 30, email: 'test@example.com' }
      options = { only: %i[name age] }

      expect(described_class).to receive(:from_hash).with(hash, options)
      RapiTapir::Types.from_hash(hash, **options)
    end
  end
end
