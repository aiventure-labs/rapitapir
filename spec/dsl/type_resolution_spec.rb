# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::DSL::TypeResolution do
  include RapiTapir::DSL::TypeResolution

  it 'raises for unknown primitive symbols' do
    expect { send(:create_primitive_type, :not_a_type) }.to raise_error(ArgumentError, /Unknown primitive type/)
  end

  it 'passes through resolvable classes or types' do
    expect(send(:resolve_type, RapiTapir::Types.string)).to be_a(RapiTapir::Types::String)
  end
end

RSpec.describe RapiTapir::DSL::InputMethods do
  include RapiTapir::DSL::InputMethods
  include RapiTapir::DSL::TypeResolution

  it 'accumulates inputs using json_body and body' do
    @inputs = []
    json_body({ 'name' => :string })
    body({ 'age' => :integer })
    expect(@inputs.size).to eq(2)
    kinds = @inputs.map(&:kind)
    expect(kinds).to all(eq(:body))
  end
end
