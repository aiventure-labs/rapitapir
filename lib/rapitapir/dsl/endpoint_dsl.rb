# frozen_string_literal: true

require_relative '../core/input'
require_relative '../core/output'

module RapiTapir
  module DSL
    # DSL helpers for endpoint input definitions
    def query(name, type, options = {})
      validate_input_params!(name, type)
      Core::Input.new(kind: :query, name: name, type: type, options: options)
    end

    def path_param(name, type, options = {})
      validate_input_params!(name, type)
      Core::Input.new(kind: :path, name: name, type: type, options: options)
    end

    def header(name, type, options = {})
      validate_input_params!(name, type)
      Core::Input.new(kind: :header, name: name, type: type, options: options)
    end

    def body(type, options = {})
      validate_type!(type)
      Core::Input.new(kind: :body, name: :body, type: type, options: options)
    end

    # DSL helpers for endpoint output definitions
    def json_body(schema)
      validate_schema!(schema)
      Core::Output.new(kind: :json, type: schema)
    end

    def xml_body(schema)
      validate_schema!(schema)
      Core::Output.new(kind: :xml, type: schema)
    end

    def status_code(code)
      validate_status_code!(code)
      Core::Output.new(kind: :status, type: code)
    end

    # DSL helpers for endpoint metadata
    def description(text)
      validate_string!(text, 'description')
      { description: text }
    end

    def summary(text)
      validate_string!(text, 'summary')
      { summary: text }
    end

    def tag(name)
      validate_string!(name, 'tag')
      { tag: name }
    end

    def example(data)
      { example: data }
    end

    def deprecated(flag = true)
      { deprecated: !!flag }
    end

    def error_description(text)
      validate_string!(text, 'error_description')
      { error_description: text }
    end

    private

    def validate_input_params!(name, type)
      raise ArgumentError, 'Input name cannot be nil' if name.nil?
      raise ArgumentError, 'Input name must be a symbol or string' unless name.is_a?(Symbol) || name.is_a?(String)
      validate_type!(type)
    end

    def validate_type!(type)
      valid_types = [:string, :integer, :float, :boolean, :date, :datetime]
      return if valid_types.include?(type) || type.is_a?(Hash) || type.is_a?(Class)
      
      raise ArgumentError, "Invalid type: #{type}. Must be one of #{valid_types} or a Hash/Class"
    end

    def validate_schema!(schema)
      return if schema.is_a?(Hash) || schema.is_a?(Class) || schema.is_a?(Symbol) || schema.is_a?(Array)
      
      raise ArgumentError, "Invalid schema: #{schema}. Must be a Hash, Class, Symbol, or Array"
    end

    def validate_status_code!(code)
      unless code.is_a?(Integer) && code >= 100 && code <= 599
        raise ArgumentError, "Invalid status code: #{code}. Must be an integer between 100-599"
      end
    end

    def validate_string!(value, name)
      unless value.is_a?(String) && !value.empty?
        raise ArgumentError, "#{name} must be a non-empty string"
      end
    end
  end
end
