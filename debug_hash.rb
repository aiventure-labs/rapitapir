#!/usr/bin/env ruby
# frozen_string_literal: true

# Test === operator behavior
puts '=== Testing === operator ==='
puts "Hash === Hash: #{Hash.is_a?(Hash)}"
puts "Hash === {}: #{{}.is_a?(Hash)}"
puts "Array === Array: #{Array.is_a?(Array)}"
puts "Array === []: #{[].is_a?(Array)}"

# The issue is that case uses ===, and Class === Class is false
# but Class === instance is true

puts "\n=== Testing workaround ==="
case Hash
when ->(t) { t == Hash }
  puts 'Lambda workaround works for Hash'
else
  puts 'Lambda workaround failed for Hash'
end
