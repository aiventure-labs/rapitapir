# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::DSL do
  include RapiTapir::DSL

  describe 'input helpers' do
    describe '#query' do
      it 'creates a query input' do
        input = query(:name, :string)

        expect(input.kind).to eq(:query)
        expect(input.name).to eq(:name)
        expect(input.type).to eq(:string)
      end

      it 'validates input parameters' do
        expect { query(nil, :string) }.to raise_error(ArgumentError)
        expect { query(:name, :invalid) }.to raise_error(ArgumentError)
      end

      it 'accepts options' do
        input = query(:name, :string, optional: true)

        expect(input.options[:optional]).to be(true)
      end
    end

    describe '#path_param' do
      it 'creates a path parameter input' do
        input = path_param(:id, :integer)

        expect(input.kind).to eq(:path)
        expect(input.name).to eq(:id)
        expect(input.type).to eq(:integer)
      end
    end

    describe '#header' do
      it 'creates a header input' do
        input = header(:authorization, :string)

        expect(input.kind).to eq(:header)
        expect(input.name).to eq(:authorization)
        expect(input.type).to eq(:string)
      end
    end

    describe '#body' do
      it 'creates a body input' do
        input = body({ name: :string, age: :integer })

        expect(input.kind).to eq(:body)
        expect(input.name).to eq(:body)
        expect(input.type).to eq({ name: :string, age: :integer })
      end
    end
  end

  describe 'output helpers' do
    describe '#json_body' do
      it 'creates a JSON output' do
        output = json_body({ message: :string })

        expect(output.kind).to eq(:json)
        expect(output.type).to eq({ message: :string })
      end

      it 'validates schema' do
        expect { json_body(nil) }.to raise_error(ArgumentError)
      end
    end

    describe '#xml_body' do
      it 'creates an XML output' do
        output = xml_body({ message: :string })

        expect(output.kind).to eq(:xml)
        expect(output.type).to eq({ message: :string })
      end
    end

    describe '#status_code' do
      it 'creates a status output' do
        output = status_code(200)

        expect(output.kind).to eq(:status)
        expect(output.type).to eq(200)
      end

      it 'validates status codes' do
        expect { status_code(999) }.to raise_error(ArgumentError)
        expect { status_code('200') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'metadata helpers' do
    describe '#description' do
      it 'returns description metadata' do
        result = description('Test description')

        expect(result).to eq({ description: 'Test description' })
      end

      it 'validates input' do
        expect { description('') }.to raise_error(ArgumentError)
        expect { description(nil) }.to raise_error(ArgumentError)
      end
    end

    describe '#summary' do
      it 'returns summary metadata' do
        result = summary('Test summary')

        expect(result).to eq({ summary: 'Test summary' })
      end
    end

    describe '#tag' do
      it 'returns tag metadata' do
        result = tag('users')

        expect(result).to eq({ tag: 'users' })
      end
    end

    describe '#example' do
      it 'returns example metadata' do
        data = { name: 'John', age: 30 }
        result = example(data)

        expect(result).to eq({ example: data })
      end
    end

    describe '#deprecated' do
      it 'returns deprecated metadata as true by default' do
        result = deprecated

        expect(result).to eq({ deprecated: true })
      end

      it 'accepts explicit boolean values' do
        expect(deprecated(false)).to eq({ deprecated: false })
        expect(deprecated(true)).to eq({ deprecated: true })
      end
    end

    describe '#error_description' do
      it 'returns error description metadata' do
        result = error_description('Not found')

        expect(result).to eq({ error_description: 'Not found' })
      end
    end
  end
end

RSpec.describe 'DSL integration with Endpoint' do
  include RapiTapir::DSL

  it 'builds a complete endpoint with DSL' do
    endpoint = RapiTapir::Core::Endpoint.get('/users/:id')
                                        .in(path_param(:id, :integer))
                                        .in(query(:include, :string, optional: true))
                                        .in(header(:authorization, :string))
                                        .out(status_code(200))
                                        .out(json_body({ id: :integer, name: :string, email: :string }))
                                        .error_out(404, json_body({ error: :string }))
                                        .error_out(401, json_body({ error: :string }))
                                        .description('Get user by ID')
                                        .summary('User retrieval')
                                        .tag('users')

    expect(endpoint.method).to eq(:get)
    expect(endpoint.path).to eq('/users/:id')
    expect(endpoint.inputs.length).to eq(3)
    expect(endpoint.outputs.length).to eq(2)
    expect(endpoint.errors.length).to eq(2)
    expect(endpoint.metadata[:description]).to eq('Get user by ID')
    expect(endpoint.metadata[:summary]).to eq('User retrieval')
    expect(endpoint.metadata[:tag]).to eq('users')
  end

  it 'validates inputs and outputs correctly' do
    endpoint = RapiTapir::Core::Endpoint.post('/users')
                                        .in(body({ name: :string, email: :string }))
                                        .out(status_code(201))
                                        .out(json_body({ id: :integer, name: :string, email: :string }))

    # Valid input and output
    expect do
      endpoint.validate!(
        { body: { name: 'John', email: 'john@example.com' } },
        { id: 1, name: 'John', email: 'john@example.com' }
      )
    end.not_to raise_error

    # Invalid input
    expect do
      endpoint.validate!({ body: { name: 123, email: 'john@example.com' } })
    end.to raise_error(TypeError)

    # Invalid output
    expect do
      endpoint.validate!({}, { id: 'not-integer', name: 'John', email: 'john@example.com' })
    end.to raise_error(TypeError)
  end
end
