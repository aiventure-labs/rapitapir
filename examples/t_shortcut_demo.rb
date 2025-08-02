#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstration: T shortcut works immediately without any setup

require_relative '../lib/rapitapir'
require_relative '../lib/rapitapir/sinatra_rapitapir'

puts "🎯 Testing automatic T shortcut availability..."
puts

# Test 1: Top-level usage
puts "✅ Top-level usage:"
BOOK_SCHEMA = T.hash({
  "id" => T.integer,
  "title" => T.string(min_length: 1),
  "published" => T.boolean
})
puts "   BOOK_SCHEMA = T.hash(...) ✓"
puts "   Schema type: #{BOOK_SCHEMA.class}"
puts

# Test 2: Inside a class
puts "✅ Inside a class:"
class DemoAPI < SinatraRapiTapir
  USER_SCHEMA = T.hash({
    "name" => T.string,
    "email" => T.email,
    "age" => T.optional(T.integer(min: 0))
  })
  
  puts "   USER_SCHEMA = T.hash(...) ✓"
  puts "   Schema type: #{USER_SCHEMA.class}"
end
puts

# Test 3: Complex nested types
puts "✅ Complex nested types:"
COMPLEX_SCHEMA = T.hash({
  "user" => T.hash({
    "profile" => T.optional(T.hash({
      "preferences" => T.array(T.string),
      "settings" => T.hash({
        "theme" => T.string,
        "notifications" => T.boolean
      })
    }))
  }),
  "metadata" => T.hash({
    "version" => T.string,
    "timestamp" => T.datetime
  })
})
puts "   Complex nested schema created ✓"
puts "   Schema type: #{COMPLEX_SCHEMA.class}"
puts

puts "🎉 All tests passed! T shortcut works everywhere automatically!"
puts "📝 No manual setup required - just `require 'rapitapir'` and use T.* anywhere!"
