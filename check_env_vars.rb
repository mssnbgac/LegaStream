#!/usr/bin/env ruby
# Check if environment variables are loaded

require 'dotenv/load'

puts "=" * 80
puts "ENVIRONMENT VARIABLES CHECK"
puts "=" * 80
puts ""

puts "AI_PROVIDER: #{ENV['AI_PROVIDER'] || '[NOT SET]'}"
puts "GEMINI_API_KEY: #{ENV['GEMINI_API_KEY'] ? ENV['GEMINI_API_KEY'][0..20] + '...' : '[NOT SET]'}"
puts "DEVELOPMENT_MODE: #{ENV['DEVELOPMENT_MODE'] || '[NOT SET]'}"
puts ""

# Test AI Provider
require_relative 'app/services/ai_provider'

provider = AIProvider.new
puts "AI Provider initialized:"
puts "  Provider: #{provider.provider_name}"
puts "  Enabled: #{provider.enabled?}"
puts ""

if provider.enabled?
  puts "✅ AI Provider is ready to use!"
else
  puts "❌ AI Provider is NOT enabled"
  puts "   Check your .env file and make sure GEMINI_API_KEY is set"
end
