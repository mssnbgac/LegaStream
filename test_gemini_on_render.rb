#!/usr/bin/env ruby
# Test Gemini API from Render environment

require 'net/http'
require 'json'
require 'uri'
require 'dotenv/load'

puts "Testing Gemini API..."
puts "API Key: #{ENV['GEMINI_API_KEY'] ? ENV['GEMINI_API_KEY'][0..10] + '...' : 'NOT SET'}"

api_key = ENV['GEMINI_API_KEY']

unless api_key
  puts "ERROR: GEMINI_API_KEY not set in environment"
  exit 1
end

# Simple test prompt
prompt = <<~PROMPT
  Extract entities from this text. Return ONLY JSON.
  
  Text: "Acme Corporation agrees to pay John Smith $75,000 on March 1, 2026 at 123 Main Street, New York."
  
  JSON format:
  {"entities":[{"type":"PARTY","value":"Acme Corp","context":"","confidence":0.98}]}
PROMPT

uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=#{api_key}")

request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = {
  contents: [{
    parts: [{ text: prompt }]
  }],
  generationConfig: {
    temperature: 0.2,
    maxOutputTokens: 2000
  }
}.to_json

puts "\nSending request to Gemini API..."

begin
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) do |http|
    http.request(request)
  end

  puts "Response status: #{response.code}"
  
  data = JSON.parse(response.body)
  
  if data['error']
    puts "\n❌ API ERROR:"
    puts "  Code: #{data['error']['code']}"
    puts "  Message: #{data['error']['message']}"
    puts "  Status: #{data['error']['status']}"
    exit 1
  end
  
  if data['candidates'] && data['candidates'][0]
    text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    puts "\n✅ SUCCESS!"
    puts "Response text:"
    puts text
    puts "\nFinish reason: #{data['candidates'][0]['finishReason']}"
  else
    puts "\n❌ No candidates in response"
    puts "Full response:"
    puts JSON.pretty_generate(data)
  end
  
rescue Net::ReadTimeout => e
  puts "\n❌ TIMEOUT: Request took longer than 30 seconds"
  puts "Error: #{e.message}"
rescue => e
  puts "\n❌ ERROR: #{e.class}"
  puts "Message: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end
