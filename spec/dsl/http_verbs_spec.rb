# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::DSL::HTTPVerbs do
  describe 'HTTP Verb DSL methods' do
    context 'when included in a class' do
      let(:test_class) do
        Class.new do
          include RapiTapir::DSL::HTTPVerbs
        end
      end

      let(:instance) { test_class.new }

      describe '#GET' do
        it 'creates a GET endpoint builder' do
          builder = instance.GET('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:get)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end

        it 'returns the same result as RapiTapir.get' do
          path = '/api/users'
          builder1 = instance.GET(path)
          builder2 = RapiTapir.get(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#POST' do
        it 'creates a POST endpoint builder' do
          builder = instance.POST('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:post)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end

        it 'returns the same result as RapiTapir.post' do
          path = '/api/users'
          builder1 = instance.POST(path)
          builder2 = RapiTapir.post(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#PUT' do
        it 'creates a PUT endpoint builder' do
          builder = instance.PUT('/users/123')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:put)
          expect(builder.instance_variable_get(:@path)).to eq('/users/123')
        end

        it 'returns the same result as RapiTapir.put' do
          path = '/api/users/123'
          builder1 = instance.PUT(path)
          builder2 = RapiTapir.put(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#PATCH' do
        it 'creates a PATCH endpoint builder' do
          builder = instance.PATCH('/users/123')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:patch)
          expect(builder.instance_variable_get(:@path)).to eq('/users/123')
        end

        it 'returns the same result as RapiTapir.patch' do
          path = '/api/users/123'
          builder1 = instance.PATCH(path)
          builder2 = RapiTapir.patch(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#DELETE' do
        it 'creates a DELETE endpoint builder' do
          builder = instance.DELETE('/users/123')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:delete)
          expect(builder.instance_variable_get(:@path)).to eq('/users/123')
        end

        it 'returns the same result as RapiTapir.delete' do
          path = '/api/users/123'
          builder1 = instance.DELETE(path)
          builder2 = RapiTapir.delete(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#HEAD' do
        it 'creates a HEAD endpoint builder' do
          builder = instance.HEAD('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:head)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end

        it 'returns the same result as RapiTapir.head' do
          path = '/api/users'
          builder1 = instance.HEAD(path)
          builder2 = RapiTapir.head(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe '#OPTIONS' do
        it 'creates an OPTIONS endpoint builder' do
          builder = instance.OPTIONS('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:options)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end

        it 'returns the same result as RapiTapir.options' do
          path = '/api/users'
          builder1 = instance.OPTIONS(path)
          builder2 = RapiTapir.options(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end
    end

    context 'when used globally through RapiTapir module' do
      describe 'RapiTapir.GET' do
        it 'creates a GET endpoint builder' do
          builder = RapiTapir.GET('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:get)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end

        it 'returns the same result as RapiTapir.get' do
          path = '/api/users'
          builder1 = RapiTapir.GET(path)
          builder2 = RapiTapir.get(path)

          expect(builder1.instance_variable_get(:@method)).to eq(builder2.instance_variable_get(:@method))
          expect(builder1.instance_variable_get(:@path)).to eq(builder2.instance_variable_get(:@path))
        end
      end

      describe 'RapiTapir.POST' do
        it 'creates a POST endpoint builder' do
          builder = RapiTapir.POST('/users')
          expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
          expect(builder.instance_variable_get(:@method)).to eq(:post)
          expect(builder.instance_variable_get(:@path)).to eq('/users')
        end
      end

      # Testing other verbs through global access
      %w[PUT PATCH DELETE HEAD OPTIONS].each do |verb|
        describe "RapiTapir.#{verb}" do
          it "creates a #{verb} endpoint builder" do
            builder = RapiTapir.send(verb, '/test')
            expect(builder).to be_a(RapiTapir::DSL::FluentEndpointBuilder)
            expect(builder.instance_variable_get(:@method)).to eq(verb.downcase.to_sym)
            expect(builder.instance_variable_get(:@path)).to eq('/test')
          end
        end
      end
    end

    context 'functional endpoint building' do
      include RapiTapir::DSL::HTTPVerbs

      it 'builds complete endpoints using the enhanced DSL' do
        # Test a complete GET endpoint
        get_endpoint = GET('/users')
                       .summary('Get all users')
                       .description('Returns a list of all users')
                       .tags('Users')
                       .ok(RapiTapir::Types.array(
                             RapiTapir::Types.hash({
                                                     'id' => RapiTapir::Types.integer,
                                                     'name' => RapiTapir::Types.string
                                                   })
                           ))
                       .build

        expect(get_endpoint).to be_a(RapiTapir::Core::EnhancedEndpoint)
        expect(get_endpoint.method).to eq(:get)
        expect(get_endpoint.path).to eq('/users')
        expect(get_endpoint.metadata[:summary]).to eq('Get all users')
        expect(get_endpoint.metadata[:description]).to eq('Returns a list of all users')
        expect(get_endpoint.metadata[:tags]).to eq(['Users'])
      end

      it 'builds POST endpoints with body parameters' do
        post_endpoint = POST('/users')
                        .summary('Create a user')
                        .body(RapiTapir::Types.hash({
                                                      'name' => RapiTapir::Types.string,
                                                      'email' => RapiTapir::Types.string
                                                    }))
                        .created(RapiTapir::Types.hash({
                                                         'id' => RapiTapir::Types.integer,
                                                         'name' => RapiTapir::Types.string,
                                                         'email' => RapiTapir::Types.string
                                                       }))
                        .build

        expect(post_endpoint).to be_a(RapiTapir::Core::EnhancedEndpoint)
        expect(post_endpoint.method).to eq(:post)
        expect(post_endpoint.path).to eq('/users')
        expect(post_endpoint.metadata[:summary]).to eq('Create a user')
      end

      it 'builds endpoints with path parameters' do
        put_endpoint = PUT('/users/:id')
                       .path_param(:id, RapiTapir::Types.integer)
                       .summary('Update a user')
                       .body(RapiTapir::Types.hash({
                                                     'name' => RapiTapir::Types.optional(RapiTapir::Types.string),
                                                     'email' => RapiTapir::Types.optional(RapiTapir::Types.string)
                                                   }))
                       .ok(RapiTapir::Types.hash({
                                                   'id' => RapiTapir::Types.integer,
                                                   'name' => RapiTapir::Types.string,
                                                   'email' => RapiTapir::Types.string
                                                 }))
                       .build

        expect(put_endpoint).to be_a(RapiTapir::Core::EnhancedEndpoint)
        expect(put_endpoint.method).to eq(:put)
        expect(put_endpoint.path).to eq('/users/:id')
      end

      it 'builds endpoints with query parameters' do
        get_endpoint = GET('/users/search')
                       .query(:q, RapiTapir::Types.string)
                       .query(:limit, RapiTapir::Types.optional(RapiTapir::Types.integer))
                       .summary('Search users')
                       .ok(RapiTapir::Types.array(
                             RapiTapir::Types.hash({
                                                     'id' => RapiTapir::Types.integer,
                                                     'name' => RapiTapir::Types.string
                                                   })
                           ))
                       .build

        expect(get_endpoint).to be_a(RapiTapir::Core::EnhancedEndpoint)
        expect(get_endpoint.method).to eq(:get)
        expect(get_endpoint.path).to eq('/users/search')
      end
    end

    context 'Sinatra integration' do
      it 'works seamlessly with Sinatra Extension' do
        # Create a test class that uses the enhanced DSL
        api_class = Class.new do
          extend RapiTapir::DSL::HTTPVerbs

          def self.build_hello_endpoint
            GET('/hello')
              .query(:name, RapiTapir::Types.optional(RapiTapir::Types.string))
              .summary('Say hello')
              .ok(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string }))
              .build
          end
        end

        endpoint = api_class.build_hello_endpoint

        expect(endpoint).to be_a(RapiTapir::Core::EnhancedEndpoint)
        expect(endpoint.method).to eq(:get)
        expect(endpoint.path).to eq('/hello')
        expect(endpoint.metadata[:summary]).to eq('Say hello')
      end
    end

    context 'method case sensitivity' do
      include RapiTapir::DSL::HTTPVerbs

      it 'uses uppercase method names for clarity' do
        expect { GET('/test') }.not_to raise_error
        expect { POST('/test') }.not_to raise_error
        expect { PUT('/test') }.not_to raise_error
        expect { PATCH('/test') }.not_to raise_error
        expect { DELETE('/test') }.not_to raise_error
        expect { HEAD('/test') }.not_to raise_error
        expect { OPTIONS('/test') }.not_to raise_error
      end

      it 'produces the same results regardless of case style' do
        get_builder = GET('/test')
        rapitapir_builder = RapiTapir.get('/test')

        expect(get_builder.instance_variable_get(:@method)).to eq(rapitapir_builder.instance_variable_get(:@method))
        expect(get_builder.instance_variable_get(:@path)).to eq(rapitapir_builder.instance_variable_get(:@path))
      end
    end
  end
end
