# frozen_string_literal: true

module RapiTapir
  module Observability
    module HealthCheck
      class Check
        attr_reader :name, :description, :check_block

        def initialize(name, description = nil, &block)
          @name = name
          @description = description || name.to_s.gsub('_', ' ').capitalize
          @check_block = block
        end

        def call
          start_time = Time.now

          begin
            result = @check_block.call
            duration = Time.now - start_time

            case result
            when TrueClass, FalseClass
              status = result ? :healthy : :unhealthy
              create_result(status, nil, duration)
            when Hash
              status = result.fetch(:status, :healthy)
              message = result[:message]
              create_result(status, message, duration)
            else
              create_result(:healthy, result.to_s, duration)
            end
          rescue StandardError => e
            duration = Time.now - start_time
            create_result(:unhealthy, "#{e.class}: #{e.message}", duration)
          end
        end

        private

        def create_result(status, message, duration)
          {
            name: @name,
            description: @description,
            status: status,
            message: message,
            duration_ms: (duration * 1000).round(2),
            timestamp: Time.now.utc.iso8601
          }
        end
      end

      class Registry
        def initialize
          @checks = []
          register_default_checks
        end

        def register(name, description = nil, &block)
          @checks << Check.new(name, description, &block)
        end

        def run_all
          results = @checks.map(&:call)
          overall_status = results.all? { |r| r[:status] == :healthy } ? :healthy : :unhealthy

          {
            status: overall_status,
            timestamp: Time.now.utc.iso8601,
            service: 'rapitapir',
            version: RapiTapir::VERSION,
            checks: results
          }
        end

        def run_check(name)
          check = @checks.find { |c| c.name.to_s == name.to_s }
          return { error: "Check '#{name}' not found" } unless check

          check.call
        end

        def check_names
          @checks.map(&:name)
        end

        private

        def register_default_checks
          # Basic Ruby runtime check
          register(:ruby_runtime, 'Ruby runtime health') do
            {
              status: :healthy,
              message: "Ruby #{RUBY_VERSION} running on #{RUBY_PLATFORM}"
            }
          end

          # Memory usage check
          register(:memory_usage, 'Memory usage') do
            if defined?(GC)
              stats = GC.stat
              {
                status: :healthy,
                message: "Heap size: #{stats[:heap_available_slots]}, Live objects: #{stats[:heap_live_slots]}"
              }
            else
              { status: :healthy, message: 'GC stats not available' }
            end
          end

          # Thread count check
          register(:thread_count, 'Active thread count') do
            count = Thread.list.count
            status = count > 100 ? :warning : :healthy
            {
              status: status,
              message: "Active threads: #{count}"
            }
          end
        end
      end

      class Endpoint
        def initialize(registry, path = '/health')
          @registry = registry
          @path = path
        end

        def call(env)
          request = Rack::Request.new(env)

          case request.path_info
          when @path
            handle_overall_health
          when "#{@path}/check"
            handle_individual_check(request.params['name'])
          when "#{@path}/checks"
            handle_checks_list
          else
            [404, {}, ['Not Found']]
          end
        rescue StandardError => e
          [500, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                           error: 'Internal server error',
                                                                           message: e.message
                                                                         })]]
        end

        private

        def handle_overall_health
          result = @registry.run_all
          status_code = result[:status] == :healthy ? 200 : 503

          [status_code, json_headers, [JSON.generate(result)]]
        end

        def handle_individual_check(name)
          return [400, json_headers, [JSON.generate({ error: 'Missing check name parameter' })]] unless name

          result = @registry.run_check(name)
          status_code = result[:status] == :healthy ? 200 : 503

          [status_code, json_headers, [JSON.generate(result)]]
        end

        def handle_checks_list
          checks = @registry.check_names.map do |name|
            {
              name: name,
              url: "#{@path}/check?name=#{name}"
            }
          end

          [200, json_headers, [JSON.generate({
                                               available_checks: checks,
                                               total: checks.length
                                             })]]
        end

        def json_headers
          { 'Content-Type' => 'application/json' }
        end
      end

      class << self
        attr_reader :registry

        def configure(endpoint: '/health')
          @registry = Registry.new
          @endpoint_path = endpoint
        end

        def register(name, description = nil, &block)
          @registry ||= Registry.new
          @registry.register(name, description, &block)
        end

        def endpoint
          @registry ||= Registry.new
          Endpoint.new(@registry, @endpoint_path || '/health')
        end

        def enabled?
          RapiTapir::Observability.config.health_check.enabled
        end

        def run_all
          return { error: 'Health checks disabled' } unless enabled?

          @registry ||= Registry.new
          @registry.run_all
        end
      end
    end
  end
end
