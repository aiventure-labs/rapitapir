# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::CLI::Validator do
  include RapiTapir::DSL

  let(:valid_endpoints) do
    [
      RapiTapir.get('/users')
               .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                  'name' => RapiTapir::Types.string })))
               .summary('Get all users')
               .description('Retrieve a list of all users')
               .build,

      RapiTapir.post('/users')
               .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string,
                                                  'email' => RapiTapir::Types.string }))
               .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                           'email' => RapiTapir::Types.string }))
               .summary('Create user')
               .description('Create a new user')
               .build,

      RapiTapir.get('/users/:id')
               .path_param(:id, :integer)
               .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                           'email' => RapiTapir::Types.string }))
               .summary('Get user by ID')
               .description('Get a specific user by their ID')
               .build
    ]
  end

  let(:validator) { described_class.new(valid_endpoints) }

  describe '#initialize' do
    it 'sets endpoints' do
      expect(validator.endpoints).to eq(valid_endpoints)
    end
  end

  describe '#validate' do
    context 'with valid endpoints' do
      it 'returns true for valid endpoints' do
        expect(validator.validate).to be(true)
      end

      it 'has no errors for valid endpoints' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'with invalid endpoints' do
      let(:invalid_endpoints) do
        [
          # Missing output definition
          RapiTapir.get('/no-output')
                   .summary('No output endpoint')
                   .build,

          # Missing summary
          RapiTapir.get('/no-summary')
                   .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer }))
                   .build,

          # Conflicting parameters
          RapiTapir.post('/conflicting')
                   .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string }))
                   .json_body(RapiTapir::Types.hash({ 'email' => RapiTapir::Types.string })) # Duplicate body
                   .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer }))
                   .summary('Conflicting parameters')
                   .build
        ]
      end

      let(:validator) { described_class.new(invalid_endpoints) }

      it 'returns false for invalid endpoints' do
        expect(validator.validate).to be(false)
      end

      it 'collects validation errors' do
        validator.validate
        errors = validator.errors

        expect(errors).not_to be_empty
        expect(errors.any? { |e| e.include?('missing output definition') }).to be(true)
        expect(errors.any? { |e| e.include?('missing summary') }).to be(true)
        # NOTE: Multiple body parameters validation requires proper DSL chaining support
      end
    end

    context 'with mixed valid and invalid endpoints' do
      let(:mixed_endpoints) do
        [
          valid_endpoints.first, # Valid endpoint
          RapiTapir.get('/invalid')
                   .summary('Invalid endpoint') # Missing output
                   .build
        ]
      end

      let(:validator) { described_class.new(mixed_endpoints) }

      it 'returns false when any endpoint is invalid' do
        expect(validator.validate).to be(false)
      end

      it 'only reports errors for invalid endpoints' do
        validator.validate
        expect(validator.errors.size).to eq(1)
        # Error message format is "Endpoint X: message", not path-based
        expect(validator.errors.first).to include('Endpoint 2')
        expect(validator.errors.first).to include('missing output definition')
      end
    end
  end

  describe '#errors' do
    it 'returns empty array initially' do
      expect(validator.errors).to eq([])
    end

    it 'accumulates errors during validation' do
      invalid_endpoint = RapiTapir.get('/test').summary('Test').build # Missing output
      validator = described_class.new([invalid_endpoint])

      validator.validate
      expect(validator.errors).not_to be_empty
      expect(validator.errors.first).to include('missing output definition')
    end
  end

  describe 'private validation methods' do
    describe '#validate_endpoint' do
      it 'validates individual endpoints correctly' do
        valid_endpoint = valid_endpoints.first
        initial_error_count = validator.errors.length
        validator.send(:validate_endpoint, valid_endpoint, 0)
        expect(validator.errors.length).to eq(initial_error_count)

        invalid_endpoint = RapiTapir.get('/test').build # Missing summary and output
        validator.send(:validate_endpoint, invalid_endpoint, 1)
        expect(validator.errors.length).to be > initial_error_count
      end
    end

    describe '#validate_basic_properties' do
      it 'checks for required properties' do
        endpoint_without_summary = RapiTapir.get('/test')
                                            .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer }))
                                            .build

        validator.send(:validate_basic_properties, endpoint_without_summary)
        expect(validator.errors.last).to include('missing summary')

        endpoint_without_output = RapiTapir.get('/test2')
                                           .summary('Test')
                                           .build

        validator.send(:validate_basic_properties, endpoint_without_output)
        expect(validator.errors.last).to include('missing output definition')
      end
    end

    describe '#validate_parameters' do
      it 'validates parameter consistency' do
        # Multiple body parameters
        endpoint_with_multiple_bodies = double('endpoint',
                                               method: 'POST',
                                               path: '/test',
                                               summary: 'Test',
                                               input_specs: [
                                                 double('input_spec', type: :body, name: 'body1'),
                                                 double('input_spec', type: :body, name: 'body2')
                                               ])

        validator.send(:validate_parameters, endpoint_with_multiple_bodies)
        expect(validator.errors.last).to include('multiple body parameters')
      end

      it 'validates parameter types' do
        # Test with a parameter that has an unsupported type
        endpoint_with_invalid_param = double('endpoint',
                                             method: 'GET',
                                             path: '/test',
                                             summary: 'Test',
                                             input_specs: [
                                               double('input_spec',
                                                      type: :query,
                                                      name: 'param',
                                                      param_type: 'UnknownClass', # Use a string instead of symbol
                                                      metadata: {})
                                             ])

        validator.send(:validate_parameters, endpoint_with_invalid_param)
        expect(validator.errors.last).to include('invalid parameter type')
      end
    end

    describe '#valid_param_type?' do
      it 'accepts valid parameter types' do
        valid_types = [:string, :integer, :boolean, :float, :date, :datetime, Hash, Array]

        valid_types.each do |type|
          expect(validator.send(:valid_param_type?, type)).to be(true)
        end
      end

      it 'rejects invalid parameter types' do
        invalid_types = [:invalid, :unknown, nil, Object]

        invalid_types.each do |type|
          expect(validator.send(:valid_param_type?, type)).to be(false)
        end
      end
    end

    describe '#validate_output_definition' do
      it 'validates output definitions' do
        endpoint_with_output = double('endpoint',
                                      method: 'GET',
                                      path: '/test',
                                      outputs: [double('output')])

        endpoint_without_output = double('endpoint',
                                         method: 'GET',
                                         path: '/test',
                                         outputs: [])

        expect(validator.send(:validate_output_definition, endpoint_with_output)).to be(true)
        expect(validator.send(:validate_output_definition, endpoint_without_output)).to be(false)
      end
    end
  end

  describe 'comprehensive validation scenarios' do
    context 'REST API endpoints' do
      let(:rest_endpoints) do
        [
          # GET collection
          RapiTapir.get('/users')
                   .query(:page, :integer, required: false)
                   .query(:limit, :integer, required: false)
                   .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                      'name' => RapiTapir::Types.string, 'email' => RapiTapir::Types.string })))
                   .summary('List users')
                   .description('Get paginated list of users')
                   .build,

          # GET single resource
          RapiTapir.get('/users/:id')
                   .path_param(:id, :integer)
                   .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                               'email' => RapiTapir::Types.string }))
                   .summary('Get user')
                   .description('Get user by ID')
                   .build,

          # POST create
          RapiTapir.post('/users')
                   .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string,
                                                      'email' => RapiTapir::Types.string }))
                   .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                               'email' => RapiTapir::Types.string }))
                   .summary('Create user')
                   .description('Create new user')
                   .build,

          # PUT update
          RapiTapir.put('/users/:id')
                   .path_param(:id, :integer)
                   .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string,
                                                      'email' => RapiTapir::Types.string }))
                   .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                               'email' => RapiTapir::Types.string }))
                   .summary('Update user')
                   .description('Update existing user')
                   .build,

          # DELETE
          RapiTapir.delete('/users/:id')
                   .path_param(:id, :integer)
                   .ok(RapiTapir::Types.hash({ 'success' => RapiTapir::Types.boolean }))
                   .summary('Delete user')
                   .description('Delete user by ID')
                   .build
        ]
      end

      it 'validates complete REST API successfully' do
        validator = described_class.new(rest_endpoints)
        expect(validator.validate).to be(true)
        expect(validator.errors).to be_empty
      end
    end

    context 'endpoints with complex parameters' do
      let(:complex_endpoints) do
        [
          RapiTapir.post('/search')
                   .query(:q, :string)
                   .query(:filters, RapiTapir::Types.hash({}))
                   .query(:sort_by, :string, required: false)
                   .header('X-API-Key', :string)
                   .ok(RapiTapir::Types.hash({ 'results' => RapiTapir::Types.array(RapiTapir::Types.object),
                                               'total' => RapiTapir::Types.integer }))
                   .summary('Search with filters')
                   .description('Advanced search with complex filtering')
                   .build
        ]
      end

      it 'validates complex parameter structures' do
        validator = described_class.new(complex_endpoints)
        expect(validator.validate).to be(true)
        expect(validator.errors).to be_empty
      end
    end
  end
end
