# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails Integration Implementation Status' do
  describe 'Core components exist and are loadable' do
    it 'can load ResourceBuilder' do
      expect { require_relative '../../../lib/rapitapir/server/rails/resource_builder' }.not_to raise_error
    end

    it 'can load Routes module' do
      expect { require_relative '../../../lib/rapitapir/server/rails/routes' }.not_to raise_error
    end

    it 'ResourceBuilder class is defined' do
      require_relative '../../../lib/rapitapir/server/rails/resource_builder'
      expect(RapiTapir::Server::Rails::ResourceBuilder).to be_a(Class)
    end

    it 'Routes module is defined' do
      require_relative '../../../lib/rapitapir/server/rails/routes'
      expect(RapiTapir::Server::Rails::Routes).to be_a(Module)
    end
  end

  describe 'ResourceBuilder basic functionality' do
    let(:mock_controller) do
      Class.new do
        def self.GET(path)
          MockEndpointBuilder.new
        end

        def self.POST(path)
          MockEndpointBuilder.new
        end

        def self.PUT(path)
          MockEndpointBuilder.new
        end

        def self.DELETE(path)
          MockEndpointBuilder.new
        end
      end
    end

    let(:mock_endpoint_builder) do
      Class.new do
        def summary(text)
          self
        end

        def description(text)
          self
        end

        def then
          yield self
          self
        end

        def ok(schema)
          self
        end

        def path_param(name, type, options = {})
          self
        end

        def json_body(schema)
          self
        end

        def created(schema)
          self
        end

        def not_found(schema, options = {})
          self
        end

        def bad_request(schema, options = {})
          self
        end

        def no_content
          self
        end

        def build
          OpenStruct.new(path: '/test', method: :get)
        end

        def query(name, type, options = {})
          self
        end
      end
    end

    before do
      stub_const('MockEndpointBuilder', mock_endpoint_builder)
      require_relative '../../../lib/rapitapir/server/rails/resource_builder'
    end

    it 'can instantiate ResourceBuilder' do
      schema = double('schema')
      builder = RapiTapir::Server::Rails::ResourceBuilder.new(mock_controller, '/users', schema)
      expect(builder).to be_a(RapiTapir::Server::Rails::ResourceBuilder)
      expect(builder.endpoints).to eq([])
    end

    it 'can create index endpoint' do
      schema = double('schema')
      builder = RapiTapir::Server::Rails::ResourceBuilder.new(mock_controller, '/users', schema)
      
      expect { builder.index { [] } }.not_to raise_error
      expect(builder.endpoints.length).to eq(1)
    end
  end

  describe 'Routes module basic functionality' do
    let(:mock_router) do
      Class.new do
        include RapiTapir::Server::Rails::Routes

        def get(path, options = {})
          @routes ||= []
          @routes << { method: :get, path: path, options: options }
        end

        def routes
          @routes || []
        end
      end
    end

    before do
      require_relative '../../../lib/rapitapir/server/rails/routes'
    end

    it 'can include Routes module' do
      router = mock_router.new
      expect(router).to respond_to(:rapitapir_routes_for)
    end

    it 'can convert RapiTapir paths to Rails paths' do
      router = mock_router.new
      result = router.send(:convert_rapitapir_path_to_rails, '/users/{id}')
      expect(result).to eq('/users/:id')
    end

    it 'can generate route names' do
      router = mock_router.new
      expect(router.send(:route_name, 'users', :index, 'get')).to eq(:users)
      expect(router.send(:route_name, 'users', :show, 'get')).to eq(:user)
    end

    it 'can singularize names' do
      router = mock_router.new
      expect(router.send(:singularize_name, 'users')).to eq('user')
      expect(router.send(:singularize_name, 'books')).to eq('book')
      expect(router.send(:singularize_name, 'categories')).to eq('category')
      expect(router.send(:singularize_name, 'person')).to eq('person')
    end
  end

  describe 'HTTP verb methods integration' do
    it 'provides enhanced HTTP verb DSL' do
      expect(RapiTapir).to respond_to(:GET)
      expect(RapiTapir).to respond_to(:POST)
      expect(RapiTapir).to respond_to(:PUT)
      expect(RapiTapir).to respond_to(:DELETE)
    end

    it 'HTTP verbs return FluentEndpointBuilder' do
      expect(RapiTapir.GET('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
      expect(RapiTapir.POST('/test')).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
    end
  end

  describe 'T shortcut availability' do
    it 'T is available and points to RapiTapir::Types' do
      expect(defined?(T)).to be_truthy
      expect(T).to eq(RapiTapir::Types)
    end

    it 'provides type shortcuts' do
      expect(T.string).to be_a(RapiTapir::Types::String)
      expect(T.integer).to be_a(RapiTapir::Types::Integer)
      expect(T.boolean).to be_a(RapiTapir::Types::Boolean)
    end
  end

  describe 'Implementation completeness' do
    it 'all required files exist' do
      base_path = '/Users/riccardo/git/github/riccardomerolla/ruby-tapir'
      
      expect(File.exist?("#{base_path}/lib/rapitapir/server/rails/controller_base.rb")).to be(true)
      expect(File.exist?("#{base_path}/lib/rapitapir/server/rails/resource_builder.rb")).to be(true)
      expect(File.exist?("#{base_path}/lib/rapitapir/server/rails/routes.rb")).to be(true)
      expect(File.exist?("#{base_path}/examples/rails/enhanced_users_controller.rb")).to be(true)
      expect(File.exist?("#{base_path}/examples/rails/README.md")).to be(true)
      expect(File.exist?("#{base_path}/examples/rails/config/routes.rb")).to be(true)
    end
  end
end
