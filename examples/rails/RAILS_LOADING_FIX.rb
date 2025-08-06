# frozen_string_literal: true

# Instructions for using RapiTapir with Rails
# 
# To fix the "uninitialized constant RapiTapir::Server::Rails::ControllerBase" error:
#
# 1. In your Rails application, make sure to require 'rapitapir' AFTER Rails is loaded
# 2. In your Gemfile, add:
#    gem 'rapitapir'
# 3. In your ApplicationController or in an initializer, add:
#    require 'rapitapir' (only if needed - bundler usually handles this)
#
# The error occurs because RapiTapir's Rails integration requires Rails and ActiveSupport
# to be loaded first.

# For the traditional_app_runnable.rb example, the require order should be:

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 8.0'
  gem 'sqlite3'
  gem 'puma'
end

# Load Rails first
require 'rails/all'

# THEN load RapiTapir (this is the key!)
require_relative '../../../lib/rapitapir'

# Now you can use RapiTapir::Server::Rails::ControllerBase

puts "✅ This order works correctly!"
