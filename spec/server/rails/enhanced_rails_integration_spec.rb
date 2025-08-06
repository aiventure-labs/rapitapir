# frozen_string_literal: true

require 'spec_helper'
require 'rspec/mocks'

RSpec.describe 'Enhanced Rails Integration Components' do
  describe 'ResourceBuilder' do
    let(:controller_class) do
      # Create all doubles in the RSpec context first
      endpoint_double = double('endpoint')
      get_builder = double('fluent_builder')
      allow(get_builder).to receive_message_chain(:summary, :description, :path_param, :ok, :not_found, :build).and_return(endpoint_double)
      allow(get_builder).to receive_message_chain(:summary, :description, :then, :ok, :build).and_return(endpoint_double)
      allow(get_builder).to receive(:query).and_return(get_builder)
      
      post_builder = double('fluent_builder')  
      allow(post_builder).to receive_message_chain(:summary, :description, :json_body, :created, :bad_request, :build).and_return(endpoint_double)
      
      put_builder = double('fluent_builder')
      allow(put_builder).to receive_message_chain(:summary, :description, :path_param, :json_body, :ok, :not_found, :bad_request, :build).and_return(endpoint_double)
      
      delete_builder = double('fluent_builder')
      allow(delete_builder).to receive_message_chain(:summary, :description, :path_param, :no_content, :not_found, :build).and_return(endpoint_double)

      Class.new do
        define_singleton_method(:GET) { |path| get_builder }
        define_singleton_method(:POST) { |path| post_builder }
        define_singleton_method(:PUT) { |path| put_builder }
        define_singleton_method(:DELETE) { |path| delete_builder }
      end
    end

    let(:schema) { double('schema') }

    before do
      require_relative '../../../lib/rapitapir/server/rails/resource_builder'
    end

    let(:resource_builder) { RapiTapir::Server::Rails::ResourceBuilder.new(controller_class, '/users', schema) }

    describe '#initialize' do
      it 'sets up the resource builder with correct parameters' do
        builder = RapiTapir::Server::Rails::ResourceBuilder.new(controller_class, '/users', schema)
        expect(builder.endpoints).to eq([])
      end
    end

    describe '#crud' do
      it 'executes a crud block' do
        expect {
          resource_builder.crud do
            index { [] }
          end
        }.not_to raise_error
      end

      it 'respects except parameter' do
        expect {
          resource_builder.crud(except: [:destroy]) do
            index { [] }
            show { {} }
          end
        }.not_to raise_error
      end

      it 'respects only parameter' do
        expect {
          resource_builder.crud(only: [:index]) do
            index { [] }
          end
        }.not_to raise_error
      end
    end

    describe 'CRUD methods' do
      it 'creates index endpoint' do
        expect {
          resource_builder.index { [] }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end

      it 'creates show endpoint' do
        expect {
          resource_builder.show { {} }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end

      it 'creates create endpoint' do
        expect {
          resource_builder.create { {} }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end

      it 'creates update endpoint' do
        expect {
          resource_builder.update { {} }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end

      it 'creates destroy endpoint' do
        expect {
          resource_builder.destroy { {} }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end
    end

    describe '#custom' do
      it 'creates custom endpoints' do
        # Create the double chain outside the class context
        endpoint_double = double('endpoint')
        builder_chain = double('builder')
        allow(builder_chain).to receive_message_chain(:summary, :description, :build).and_return(endpoint_double)
        
        allow(controller_class).to receive(:public_send).with('GET', '/users/active')
          .and_return(builder_chain)

        expect {
          resource_builder.custom(:get, 'active') { [] }
        }.not_to raise_error

        expect(resource_builder.endpoints.length).to eq(1)
      end
    end

    describe 'private methods' do
      describe '#resource_name' do
        it 'extracts singular resource name from path' do
          name = resource_builder.send(:resource_name)
          expect(name).to eq('user')
        end
      end

      describe '#error_schema' do
        it 'returns error schema' do
          schema = resource_builder.send(:error_schema)
          expect(schema).to be_a(RapiTapir::Types::Hash)
        end
      end

      describe '#validation_error_schema' do
        it 'returns validation error schema' do
          schema = resource_builder.send(:validation_error_schema)
          expect(schema).to be_a(RapiTapir::Types::Hash)
        end
      end
    end
  end

  describe 'Routes module' do
    let(:router_class) do
      Class.new do
        include RapiTapir::Server::Rails::Routes

        def get(path, options = {})
          routes << { method: :get, path: path, options: options }
        end

        def post(path, options = {})
          routes << { method: :post, path: path, options: options }
        end

        def put(path, options = {})
          routes << { method: :put, path: path, options: options }
        end

        def delete(path, options = {})
          routes << { method: :delete, path: path, options: options }
        end

        def routes
          @routes ||= []
        end
      end
    end

    let(:router) { router_class.new }

    let(:controller_class) do
      # Create endpoints outside the class definition
      endpoints_hash = {
        index: {
          endpoint: double('endpoint', method: :get, path: '/test')
        },
        show: {
          endpoint: double('endpoint', method: :get, path: '/test/:id')
        },
        create: {
          endpoint: double('endpoint', method: :post, path: '/test')
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

    before do
      require_relative '../../../lib/rapitapir/server/rails/routes'
    end

    describe '#rapitapir_routes_for' do
      it 'generates routes for a controller' do
        router.rapitapir_routes_for(controller_class)

        expect(router.routes.length).to eq(3)
        expect(router.routes[0][:method]).to eq(:get)
        expect(router.routes[0][:path]).to eq('/test')
        expect(router.routes[1][:method]).to eq(:get)
        expect(router.routes[1][:path]).to eq('/test/:id')
        expect(router.routes[2][:method]).to eq(:post)
        expect(router.routes[2][:path]).to eq('/test')
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

      it 'handles multiple parameters' do
        result = router.send(:convert_rapitapir_path_to_rails, '/users/{user_id}/posts/{id}')
        expect(result).to eq('/users/:user_id/posts/:id')
      end
    end

    describe '#route_name' do
      it 'generates correct route names' do
        expect(router.send(:route_name, 'users', :index, 'get')).to eq(:users)
        expect(router.send(:route_name, 'users', :show, 'get')).to eq(:user)
        expect(router.send(:route_name, 'users', :create, 'post')).to eq(:users)
        expect(router.send(:route_name, 'users', :custom_action, 'get')).to eq(:get_users_custom_action)
      end
    end
  end

  describe 'Core HTTP verb methods' do
    it 'provides HTTP verb builders' do
      expect(RapiTapir.GET('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      expect(RapiTapir.POST('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      expect(RapiTapir.PUT('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      expect(RapiTapir.DELETE('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
    end
  end

  describe 'T shortcut' do
    it 'T is available as alias for RapiTapir::Types' do
      expect(defined?(T)).to be_truthy
      expect(T).to eq(RapiTapir::Types)
    end

    it 'provides common type shortcuts' do
      expect(T.string).to be_a(RapiTapir::Types::String)
      expect(T.integer).to be_a(RapiTapir::Types::Integer)
      expect(T.boolean).to be_a(RapiTapir::Types::Boolean)
      expect(T.hash({})).to be_a(RapiTapir::Types::Hash)
      expect(T.array(T.string)).to be_a(RapiTapir::Types::Array)
    end
  end
end
