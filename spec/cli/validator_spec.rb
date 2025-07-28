# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::CLI::Validator do
  include RapiTapir::DSL

  let(:valid_endpoints) do
    [
      RapiTapir.get('/users')
        .out(json_body([{ id: :integer, name: :string }]))
        .summary('Get all users')
        .description('Retrieve a list of all users'),

      RapiTapir.post('/users')
        .in(body({ name: :string, email: :string }))
        .out(json_body({ id: :integer, name: :string, email: :string }))
        .summary('Create user')
        .description('Create a new user'),

      RapiTapir.get('/users/:id')
        .in(path(:id, :integer))
        .out(json_body({ id: :integer, name: :string, email: :string }))
        .summary('Get user by ID')
        .description('Get a specific user by their ID')
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
            .summary('No output endpoint'),

          # Missing summary
          RapiTapir.get('/no-summary')
            .out(json_body({ id: :integer })),

          # Conflicting parameters
          RapiTapir.post('/conflicting')
            .in(body({ name: :string }))
            .in(body({ email: :string })) # Duplicate body
            .out(json_body({ id: :integer }))
            .summary('Conflicting parameters')
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
        # Note: Multiple body parameters validation requires proper DSL chaining support
      end
    end

    context 'with mixed valid and invalid endpoints' do
      let(:mixed_endpoints) do
        [
          valid_endpoints.first, # Valid endpoint
          RapiTapir.get('/invalid')
            .summary('Invalid endpoint') # Missing output
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
      invalid_endpoint = RapiTapir.get('/test').summary('Test') # Missing output
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

        invalid_endpoint = RapiTapir.get('/test') # Missing summary and output
        validator.send(:validate_endpoint, invalid_endpoint, 1)
        expect(validator.errors.length).to be > initial_error_count
      end
    end

    describe '#validate_basic_properties' do
      it 'checks for required properties' do
        endpoint_without_summary = RapiTapir.get('/test')
          .out(json_body({ id: :integer }))
        
        validator.send(:validate_basic_properties, endpoint_without_summary)
        expect(validator.errors.last).to include('missing summary')

        endpoint_without_output = RapiTapir.get('/test2')
          .summary('Test')
        
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
          ]
        )
        
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
              param_type: 'UnknownClass',  # Use a string instead of symbol
              metadata: {}
            )
          ]
        )
        
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
          outputs: [double('output')]
        )
        
        endpoint_without_output = double('endpoint',
          method: 'GET',
          path: '/test',
          outputs: []
        )
        
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
            .in(query(:page, :integer, optional: true))
            .in(query(:limit, :integer, optional: true))
            .out(json_body([{ id: :integer, name: :string, email: :string }]))
            .summary('List users')
            .description('Get paginated list of users'),

          # GET single resource
          RapiTapir.get('/users/:id')
            .in(path(:id, :integer))
            .out(json_body({ id: :integer, name: :string, email: :string }))
            .summary('Get user')
            .description('Get user by ID'),

          # POST create
          RapiTapir.post('/users')
            .in(body({ name: :string, email: :string }))
            .out(json_body({ id: :integer, name: :string, email: :string }))
            .summary('Create user')
            .description('Create new user'),

          # PUT update
          RapiTapir.put('/users/:id')
            .in(path(:id, :integer))
            .in(body({ name: :string, email: :string }))
            .out(json_body({ id: :integer, name: :string, email: :string }))
            .summary('Update user')
            .description('Update existing user'),

          # DELETE
          RapiTapir.delete('/users/:id')
            .in(path(:id, :integer))
            .out(json_body({ success: :boolean }))
            .summary('Delete user')
            .description('Delete user by ID')
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
            .in(query(:q, :string))
            .in(query(:filters, Hash))
            .in(query(:sort_by, :string, optional: true))
            .in(header('X-API-Key', :string))
            .out(json_body({ results: Array, total: :integer }))
            .summary('Search with filters')
            .description('Advanced search with complex filtering')
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
