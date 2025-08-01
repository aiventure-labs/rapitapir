# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Types do
  describe 'primitive types' do
    describe RapiTapir::Types::String do
      it 'validates string values' do
        type = RapiTapir::Types.string
        result = type.validate('hello')
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'rejects non-string values' do
        type = RapiTapir::Types.string
        result = type.validate(123)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Expected string/))
      end

      it 'enforces minimum length' do
        type = RapiTapir::Types.string(min_length: 5)

        result = type.validate('hi')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/below minimum/))

        result = type.validate('hello')
        expect(result[:valid]).to be true
      end

      it 'enforces maximum length' do
        type = RapiTapir::Types.string(max_length: 3)

        result = type.validate('hello')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/exceeds maximum/))

        result = type.validate('hi')
        expect(result[:valid]).to be true
      end

      it 'validates pattern' do
        type = RapiTapir::Types.string(pattern: /\A[a-z]+\z/)

        result = type.validate('Hello')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/does not match pattern/))

        result = type.validate('hello')
        expect(result[:valid]).to be true
      end

      it 'coerces values to string' do
        type = RapiTapir::Types.string
        expect(type.coerce(123)).to eq('123')
        expect(type.coerce(:symbol)).to eq('symbol')
        expect(type.coerce('string')).to eq('string')
      end
    end

    describe RapiTapir::Types::Integer do
      it 'validates integer values' do
        type = RapiTapir::Types.integer
        result = type.validate(42)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'rejects non-integer values' do
        type = RapiTapir::Types.integer
        result = type.validate('not a number')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Expected integer/))
      end

      it 'enforces minimum value' do
        type = RapiTapir::Types.integer(minimum: 10)

        result = type.validate(5)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/below minimum/))

        result = type.validate(15)
        expect(result[:valid]).to be true
      end

      it 'enforces maximum value' do
        type = RapiTapir::Types.integer(maximum: 100)

        result = type.validate(150)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/exceeds maximum/))

        result = type.validate(50)
        expect(result[:valid]).to be true
      end

      it 'coerces values to integer' do
        type = RapiTapir::Types.integer
        expect(type.coerce('42')).to eq(42)
        expect(type.coerce(42.7)).to eq(42)
        expect(type.coerce(true)).to eq(1)
        expect(type.coerce(false)).to eq(0)
      end
    end

    describe RapiTapir::Types::Boolean do
      it 'validates boolean values' do
        type = RapiTapir::Types.boolean

        result = type.validate(true)
        expect(result[:valid]).to be true

        result = type.validate(false)
        expect(result[:valid]).to be true
      end

      it 'rejects non-boolean values' do
        type = RapiTapir::Types.boolean
        result = type.validate('true')
        expect(result[:valid]).to be false
      end

      it 'coerces values to boolean' do
        type = RapiTapir::Types.boolean
        expect(type.coerce('true')).to be true
        expect(type.coerce('false')).to be false
        expect(type.coerce('1')).to be true
        expect(type.coerce('0')).to be false
        expect(type.coerce(1)).to be true
        expect(type.coerce(0)).to be false
      end
    end
  end

  describe 'semantic types' do
    describe RapiTapir::Types::UUID do
      it 'validates UUID format' do
        type = RapiTapir::Types.uuid

        result = type.validate('123e4567-e89b-12d3-a456-426614174000')
        expect(result[:valid]).to be true

        result = type.validate('not-a-uuid')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Invalid UUID format/))
      end
    end

    describe RapiTapir::Types::Email do
      it 'validates email format' do
        type = RapiTapir::Types.email

        result = type.validate('user@example.com')
        expect(result[:valid]).to be true

        result = type.validate('not-an-email')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Invalid email format/))
      end
    end
  end

  describe 'composite types' do
    describe RapiTapir::Types::Array do
      it 'validates array with item type' do
        type = RapiTapir::Types.array(RapiTapir::Types.string)

        result = type.validate(%w[hello world])
        expect(result[:valid]).to be true

        result = type.validate(['hello', 123])
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Item at index 1/))
      end

      it 'enforces min/max items' do
        type = RapiTapir::Types.array(RapiTapir::Types.string, min_items: 2, max_items: 3)

        result = type.validate(['one'])
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/below minimum/))

        result = type.validate(%w[one two three four])
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/exceeds maximum/))

        result = type.validate(%w[one two])
        expect(result[:valid]).to be true
      end

      it 'coerces array values' do
        type = RapiTapir::Types.array(RapiTapir::Types.integer)
        result = type.coerce(%w[1 2 3])
        expect(result).to eq([1, 2, 3])
      end
    end

    describe RapiTapir::Types::Object do
      it 'validates object with defined fields' do
        type = RapiTapir::Types.object do
          field :name, RapiTapir::Types.string
          field :age, RapiTapir::Types.integer
        end

        result = type.validate({ name: 'John', age: 30 })
        expect(result[:valid]).to be true

        result = type.validate({ name: 'John', age: 'thirty' })
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(match(/Field 'age'/))
      end

      it 'handles optional fields' do
        type = RapiTapir::Types.object do
          field :name, RapiTapir::Types.string
          field :age, RapiTapir::Types.integer, required: false
        end

        result = type.validate({ name: 'John' })
        expect(result[:valid]).to be true

        result = type.validate({ age: 30 })
        expect(result[:valid]).to be false # name is required
      end

      it 'coerces object values' do
        type = RapiTapir::Types.object do
          field :id, RapiTapir::Types.integer
          field :name, RapiTapir::Types.string
        end

        result = type.coerce({ 'id' => '123', 'name' => 'John' })
        expect(result).to eq({ id: 123, name: 'John' })
      end
    end

    describe RapiTapir::Types::Optional do
      it 'allows nil values' do
        type = RapiTapir::Types.optional(RapiTapir::Types.string)

        result = type.validate(nil)
        expect(result[:valid]).to be true

        result = type.validate('hello')
        expect(result[:valid]).to be true

        result = type.validate(123)
        expect(result[:valid]).to be false
      end

      it 'coerces nil to nil' do
        type = RapiTapir::Types.optional(RapiTapir::Types.string)
        expect(type.coerce(nil)).to be_nil
        expect(type.coerce('hello')).to eq('hello')
      end
    end
  end

  describe 'JSON schema generation' do
    it 'generates JSON schema for primitive types' do
      type = RapiTapir::Types.string(min_length: 1, max_length: 100)
      schema = type.to_json_schema

      expect(schema[:type]).to eq('string')
      expect(schema[:minLength]).to eq(1)
      expect(schema[:maxLength]).to eq(100)
    end

    it 'generates JSON schema for object types' do
      type = RapiTapir::Types.object do
        field :name, RapiTapir::Types.string
        field :age, RapiTapir::Types.integer, required: false
      end

      schema = type.to_json_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:properties][:name][:type]).to eq('string')
      expect(schema[:properties][:age][:type]).to eq('integer')
      expect(schema[:required]).to eq([:name])
    end

    it 'generates JSON schema for array types' do
      type = RapiTapir::Types.array(RapiTapir::Types.string, min_items: 1)
      schema = type.to_json_schema

      expect(schema[:type]).to eq('array')
      expect(schema[:items][:type]).to eq('string')
      expect(schema[:minItems]).to eq(1)
    end
  end
end
