#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

# Simple script to get an Auth0 access token for API testing
# Requires AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET, AUTH0_AUDIENCE

def get_auth0_token
  domain = ENV['AUTH0_DOMAIN']
  client_id = ENV['AUTH0_CLIENT_ID'] 
  client_secret = ENV['AUTH0_CLIENT_SECRET']
  audience = ENV['AUTH0_AUDIENCE']
  
  unless domain && client_id && client_secret && audience
    puts "❌ Missing environment variables. Required:"
    puts "   AUTH0_DOMAIN"
    puts "   AUTH0_CLIENT_ID" 
    puts "   AUTH0_CLIENT_SECRET"
    puts "   AUTH0_AUDIENCE"
    puts "\nCopy .env.example to .env and fill in your Auth0 details."
    exit 1
  end

  uri = URI("https://#{domain}/oauth/token")
  
  payload = {
    client_id: client_id,
    client_secret: client_secret,
    audience: audience,
    grant_type: 'client_credentials'
  }

  puts "🔄 Requesting token from Auth0..."
  puts "   Domain: #{domain}"
  puts "   Audience: #{audience}"
  puts "   Client ID: #{client_id[0..8]}..."

  response = Net::HTTP.post(uri, payload.to_json, {
    'Content-Type' => 'application/json'
  })

  if response.code == '200'
    token_data = JSON.parse(response.body)
    access_token = token_data['access_token']
    expires_in = token_data['expires_in']
    
    puts "✅ Token obtained successfully!"
    puts "   Expires in: #{expires_in} seconds"
    puts "   Token (first 50 chars): #{access_token[0..49]}..."
    puts
    puts "🧪 Test the API with:"
    puts "   curl -H \"Authorization: Bearer #{access_token}\" http://localhost:4567/me"
    puts
    puts "📋 Full token:"
    puts access_token
    
    return access_token
  else
    puts "❌ Failed to get token:"
    puts "   Status: #{response.code}"
    puts "   Body: #{response.body}"
    exit 1
  end
end

if __FILE__ == $0
  get_auth0_token
end
