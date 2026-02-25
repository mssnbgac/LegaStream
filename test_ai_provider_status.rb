#!/usr/bin/env ruby
require 'dotenv/load'
require_relative 'app/services/ai_provider'

puts "=" * 80
puts "AI PROVIDER STATUS CHECK"
puts "=" * 80
puts ""

puts "Environment Variables:"
puts "  AI_PROVIDER: #{ENV['AI_PROVIDER'] || '[NOT SET]'}"
puts "  GEMINI_API_KEY: #{ENV['GEMINI_API_KEY'] ? ENV['GEMINI_API_KEY'][0..20] + '...' : '[NOT SET]'}"
puts ""

provider = AIProvider.new

puts "AI Provider Object:"
puts "  Provider Name: #{provider.provider_name}"
puts "  Enabled: #{provider.enabled?}"
puts ""

if provider.enabled?
  puts "✅ AI Provider is ENABLED and ready to use"
  puts ""
  puts "Testing entity extraction..."
  
  test_text = "This agreement is between Acme Corporation and John Smith, effective March 1, 2026."
  
  begin
    entities = provider.extract_entities(test_text)
    
    if entities && entities.is_a?(Array)
      puts "✅ Entity extraction successful!"
      puts "   Extracted #{entities.length} entities:"
      entities.each do |e|
        puts "     - #{e['type']}: #{e['value']}"
      end
    else
      puts "❌ Entity extraction returned: #{entities.inspect}"
    end
  rescue => e
    puts "❌ Entity extraction failed: #{e.message}"
    puts "   #{e.class}"
  end
else
  puts "❌ AI Provider is NOT enabled"
  puts ""
  puts "Possible reasons:"
  puts "  1. GEMINI_API_KEY is not set or empty"
  puts "  2. API key is set to placeholder value 'your_api_key_here'"
  puts "  3. AI_PROVIDER is set to unsupported value"
end
