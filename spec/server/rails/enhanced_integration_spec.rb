# frozen_string_literal: true

require 'spec_helper'

# Mock Rails dependencies before requiring our classes
module ActiveSupport
  module Concern
    def self.extended(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def included(base)
        # Mock Rails concern behavior
      end
    end
  end
end

# Mock ActionController::Base
class ActionController
  class Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :rapitapir_endpoints

      def define_method(name, &block)
        # Mock define_method for testing
      end

      def controller_name
        'test'
      end
    end
  end
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
        endpoint_def = double('endpoint',
                              path: '/test',
                              method: :get,
                              validate!: true)
        
        allow(controller_class).to receive(:rapitapir_endpoint)
        allow(controller_class).to receive(:define_method)

        controller_class.endpoint(endpoint_def) { 'test' }

        expect(controller_class).to have_received(:rapitapir_endpoint)
        expect(controller_class).to have_received(:define_method)
      end
    end

    describe '.api_resource' do
      it 'creates resource endpoints using ResourceBuilder' do
        schema = double('schema')
        resource_builder = instance_double(RapiTapir::Server::Rails::ResourceBuilder,
                                           endpoints: [])
        
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
      it 'derives index for GET without :id' do
        action = controller_class.send(:derive_action_name, '/users', :get)
        expect(action).to eq(:index)
      end

      it 'derives show for GET with :id' do
        action = controller_class.send(:derive_action_name, '/users/:id', :get)
        expect(action).to eq(:show)
      end

      it 'derives create for POST' do
        action = controller_class.send(:derive_action_name, '/users', :post)
        expect(action).to eq(:create)
      end

      it 'derives update for PUT' do
        action = controller_class.send(:derive_action_name, '/users/:id', :put)
        expect(action).to eq(:update)
      end

      it 'derives destroy for DELETE' do
        action = controller_class.send(:derive_action_name, '/users/:id', :delete)
        expect(action).to eq(:destroy)
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
    Class.new do
      def self.GET(path)
        double('endpoint_builder', 
               summary: double('builder', description: double('builder', then: double('builder', ok: double('builder', build: double('endpoint'))))),
               path_param: double('builder', ok: double('builder', not_found: double('builder', build: double('endpoint')))),
               json_body: double('builder', created: double('builder', bad_request: double('builder', build: double('endpoint')))),
               no_content: double('builder', not_found: double('builder', build: double('endpoint'))))
      end

      def self.POST(path)
        GET(path)
      end

      def self.PUT(path)
        GET(path)
      end

      def self.DELETE(path)
        GET(path)
      end
    end
  end

  let(:schema) { double('schema') }
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
    Class.new do
      def self.controller_name
        'test'
      end

      def self.rapitapir_endpoints
        {
          index: {
            endpoint: double('endpoint', method: :get, path: '/test')
          },
          show: {
            endpoint: double('endpoint', method: :get, path: '/test/:id')
          }
        }
      end

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
