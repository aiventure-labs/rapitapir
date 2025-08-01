# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/observability'
require 'stringio'

RSpec.describe 'Debug Logger Creation' do
  it 'creates logger without DSL pollution' do
    # This should show us where path_param is being called from
    output = StringIO.new

    begin
      RapiTapir::Observability::Logging::StructuredLogger.new(output: output, level: :debug, format: :json)
      puts 'Logger created successfully'
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts 'Backtrace:'
      puts e.backtrace
      raise
    end
  end
end
