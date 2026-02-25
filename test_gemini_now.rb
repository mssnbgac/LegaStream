require 'net/http'
require 'json'
require 'uri'

puts "Testing Gemini API..."
puts "=" * 60

# Load API key from .env
api_key = nil
if File.exist?('.env')
  File.readlines('.env').each do |line|
    if line.start_with?('GEMINI_API_KEY=')
      api_key = line.split('=', 2)[1].strip
      break
    end
  end
end

if api_key.nil? || api_key.empty? || api_key == 'your_gemini_api_key_here'
  puts "❌ No Gemini API key found in .env file"
  exit 1
end

puts "✓ API Key found: #{api_key[0..20]}..."
puts ""

# Test API call
uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")

request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = {
  contents: [{
    parts: [{
      text: "Extract entities from this text: John Smith works at Acme Corp for $50,000. Return JSON with format: {\"entities\": [{\"type\": \"PARTY\", \"value\": \"...\", \"context\": \"...\", \"confidence\": 0.9}]}"
    }]
  }]
}.to_json

begin
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60) do |http|
    http.request(request)
  end
  
  puts "Response Code: #{response.code}"
  puts ""
  
  if response.code == '200'
    puts "✅ Gemini API is working!"
    puts ""
    puts "Response:"
    result = JSON.parse(response.body)
    if result['candidates'] && result['candidates'][0] && result['candidates'][0]['content']
      text = result['candidates'][0]['content']['parts'][0]['text']
      puts text[0..500]
    else
      puts "Response structure: #{result.inspect[0..300]}"
    end
  else
    puts "❌ Gemini API error:"
    puts response.body
  end
rescue => e
  puts "❌ Connection error: #{e.message}"
  puts e.backtrace.first(3)
end
