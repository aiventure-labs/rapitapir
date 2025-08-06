# frozen_string_literal: true

require 'spec_helper'
require 'rspec/mocks'

# Global mock for class_attribute method used by Rails concerns
def class_attribute(name, **options)
  # Mock Rails class_attribute method
  attr_accessor name
  if options[:default]
    instance_variable_set("@#{name}", options[:default])
  end
end

# Mock Rails dependencies before requiring our classes
module ActiveSupport
  module Concern
    def self.extended(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def included(base = nil, &block)
        # Mock Rails concern behavior
        # Handle both the Ruby included hook (when base is passed) 
        # and the ActiveSupport::Concern included DSL (when block is passed)
        if block_given?
          # This is the DSL version: included do...end
          # Execute the block in a context that has access to class_attribute
          block.call
        end
        # If base is passed, this is the Ruby hook - nothing special needed for mock
      end

      def class_methods(&block)
        # Mock class_methods DSL from ActiveSupport::Concern
        if block_given?
          Module.new.class_eval(&block)
        end
      end
    end
  end
end

# Mock ActionController module and Base class
module ActionController
  class Base
    # Mock Rails controller methods
    def self.class_attribute(name, **options)
      attr_accessor name
      if options[:default]
        instance_variable_set("@#{name}", options[:default])
      end
    end

    def self.controller_name
      'base'
    end

    def controller_name
      self.class.controller_name
    end
  end
end

# Remove the lazy-loaded placeholder class if it exists
if defined?(RapiTapir::Server::Rails::ControllerBase)
  RapiTapir::Server::Rails.send(:remove_const, :ControllerBase)
end

require_relative '../../../lib/rapitapir/server/rails/controller_base'
require_relative '../../../lib/rapitapir/server/rails/resource_builder'
require_relative '../../../lib/rapitapir/server/rails/routes'

RSpec.describe RapiTapir::Server::Rails::ControllerBase do
  describe 'class methods' do
    let(:controller_class) do
      Class.new(described_class) do
        def self.controller_name
          'test'
        end

        # Mock the methods that endpoint() calls
        def self.rapitapir_endpoint(action_name, endpoint_definition, &block)
          # Mock implementation
        end

        def self.define_method(name, &block)
          # Mock implementation  
        end
      end
    end

    describe '.rapitapir' do
      it 'sets up RapiTapir configuration' do
        expect {
          controller_class.rapitapir do
            info(title: 'Test API', version: '1.0.0')
          end
        }.not_to raise_error
      end
    end

    describe '.endpoint' do
      it 'registers an endpoint and creates an action' do
        endpoint_def = double('Endpoint',
                              path: '/test',
                              method: :get,
                              validate!: true)
        
        expect(controller_class).to receive(:rapitapir_endpoint)
        expect(controller_class).to receive(:define_method)

        controller_class.endpoint(endpoint_def) { 'test' }
      end
    end

    describe '.api_resource' do
      it 'creates resource endpoints using ResourceBuilder' do
        schema = double('Schema')
        resource_builder = double('ResourceBuilder', endpoints: [])
        
        allow(RapiTapir::Server::Rails::ResourceBuilder).to receive(:new)
          .and_return(resource_builder)
        allow(resource_builder).to receive(:instance_eval)

        controller_class.api_resource('/test', schema: schema) {}

        expect(RapiTapir::Server::Rails::ResourceBuilder).to have_received(:new)
          .with(controller_class, '/test', schema)
        expect(resource_builder).to have_received(:instance_eval)
      end
    end

    describe 'HTTP verb methods' do
      it 'provides GET method' do
        result = controller_class.GET('/test')
        expect(result).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      end

      it 'provides POST method' do
        result = controller_class.POST('/test')
        expect(result).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      end

      it 'provides PUT method' do
        result = controller_class.PUT('/test')
        expect(result).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      end

      it 'provides DELETE method' do
        result = controller_class.DELETE('/test')
        expect(result).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      end
    end

    describe '.derive_action_name' do
      it 'derives get_users for GET without :id' do
        action = controller_class.send(:derive_action_name, '/users', :get)
        expect(action).to eq(:get_users)
      end

      it 'derives get_users for GET with :id' do
        action = controller_class.send(:derive_action_name, '/users/:id', :get)
        expect(action).to eq(:get_users)
      end

      it 'derives post_users for POST' do
        action = controller_class.send(:derive_action_name, '/users', :post)
        expect(action).to eq(:post_users)
      end

      it 'derives put_users for PUT' do
        action = controller_class.send(:derive_action_name, '/users/:id', :put)
        expect(action).to eq(:put_users)
      end

      it 'derives delete_users for DELETE' do
        action = controller_class.send(:derive_action_name, '/users/:id', :delete)
        expect(action).to eq(:delete_users)
      end
    end
  end

  describe 'T shortcut' do
    it 'makes T available as alias for RapiTapir::Types' do
      expect(described_class::T).to eq(RapiTapir::Types)
    end
  end
end

RSpec.describe RapiTapir::Server::Rails::ResourceBuilder do
  let(:controller_class) do
    builder_mock = double('FluentEndpointBuilder')
    
    # Set up all possible method chains
    allow(builder_mock).to receive_message_chain(:summary, :description, :then, :ok, :build).and_return(double('Endpoint'))
    allow(builder_mock).to receive_message_chain(:path_param, :ok, :not_found, :build).and_return(double('Endpoint'))
    allow(builder_mock).to receive_message_chain(:json_body, :created, :bad_request, :build).and_return(double('Endpoint'))
    allow(builder_mock).to receive_message_chain(:no_content, :not_found, :build).and_return(double('Endpoint'))
    
    # Set up individual methods to return the builder itself for chaining
    allow(builder_mock).to receive(:build).and_return(double('Endpoint'))
    allow(builder_mock).to receive(:path_param).and_return(builder_mock)
    allow(builder_mock).to receive(:json_body).and_return(builder_mock)
    allow(builder_mock).to receive(:summary).and_return(builder_mock)
    allow(builder_mock).to receive(:description).and_return(builder_mock)
    allow(builder_mock).to receive(:ok).and_return(builder_mock)
    allow(builder_mock).to receive(:not_found).and_return(builder_mock)
    allow(builder_mock).to receive(:created).and_return(builder_mock)
    allow(builder_mock).to receive(:bad_request).and_return(builder_mock)
    allow(builder_mock).to receive(:no_content).and_return(builder_mock)
    allow(builder_mock).to receive(:then).and_return(builder_mock)

    Class.new do
      define_singleton_method(:GET) { |path| builder_mock }
      define_singleton_method(:POST) { |path| builder_mock }
      define_singleton_method(:PUT) { |path| builder_mock }
      define_singleton_method(:DELETE) { |path| builder_mock }
    end
  end

  let(:schema) { double('Schema') }
  let(:resource_builder) { described_class.new(controller_class, '/users', schema) }

  describe '#crud' do
    it 'enables CRUD operations with a block' do
      expect {
        resource_builder.crud do
          index { [] }
          show { {} }
        end
      }.not_to raise_error
    end

    it 'respects except option' do
      expect {
        resource_builder.crud(except: [:destroy]) do
          index { [] }
          show { {} }
        end
      }.not_to raise_error
    end

    it 'respects only option' do
      expect {
        resource_builder.crud(only: [:index, :show]) do
          index { [] }
          show { {} }
        end
      }.not_to raise_error
    end
  end

  describe 'CRUD methods' do
    it 'creates index endpoint' do
      expect {
        resource_builder.index { [] }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end

    it 'creates show endpoint' do
      expect {
        resource_builder.show { {} }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end

    it 'creates create endpoint' do
      expect {
        resource_builder.create { {} }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end

    it 'creates update endpoint' do
      expect {
        resource_builder.update { {} }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end

    it 'creates destroy endpoint' do
      expect {
        resource_builder.destroy { {} }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end
  end

  describe '#custom' do
    it 'creates custom endpoints' do
      expect {
        resource_builder.custom(:get, 'active') { [] }
      }.not_to raise_error
      
      expect(resource_builder.endpoints).not_to be_empty
    end
  end
end

RSpec.describe RapiTapir::Server::Rails::Routes do
  let(:router_class) do
    Class.new do
      include RapiTapir::Server::Rails::Routes
      
      def get(path, options = {})
        # Mock Rails route method
      end

      def post(path, options = {})
        # Mock Rails route method
      end

      def put(path, options = {})
        # Mock Rails route method
      end

      def delete(path, options = {})
        # Mock Rails route method
      end
    end
  end

  let(:router) { router_class.new }

  let(:controller_class) do
    endpoints_hash = {
      index: {
        endpoint: double('Endpoint', method: :get, path: '/test')
      },
      show: {
        endpoint: double('Endpoint', method: :get, path: '/test/:id')
      }
    }

    Class.new do
      def self.controller_name
        'test'
      end

      define_singleton_method(:rapitapir_endpoints) { endpoints_hash }

      def self.respond_to?(method)
        method == :rapitapir_endpoints
      end
    end
  end

  describe '#rapitapir_routes_for' do
    it 'generates routes for a controller' do
      allow(router).to receive(:get)
      allow(router).to receive(:post)

      router.rapitapir_routes_for(controller_class)

      expect(router).to have_received(:get).twice
    end

    it 'raises error for invalid controller' do
      invalid_controller = Class.new

      expect {
        router.rapitapir_routes_for(invalid_controller)
      }.to raise_error(ArgumentError, /must include RapiTapir::Server::Rails::Controller/)
    end
  end

  describe '#convert_rapitapir_path_to_rails' do
    it 'converts {id} format to :id format' do
      result = router.send(:convert_rapitapir_path_to_rails, '/users/{id}')
      expect(result).to eq('/users/:id')
    end

    it 'leaves :id format unchanged' do
      result = router.send(:convert_rapitapir_path_to_rails, '/users/:id')
      expect(result).to eq('/users/:id')
    end
  end
end
