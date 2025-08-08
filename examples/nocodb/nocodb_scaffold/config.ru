# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('app', __dir__)

require 'bundler/setup'
require 'rapitapir'
require 'api/app'

run API::App
