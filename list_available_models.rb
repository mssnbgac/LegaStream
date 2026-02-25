require 'net/http'
require 'json'
require 'uri'

puts "Listing available Gemini models..."
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

if api_key.nil? || api_key.empty?
  puts "❌ No Gemini API key found"
  exit 1
end

puts "✓ API Key found"
puts ""

# List models
uri = URI("https://generativelanguage.googleapis.com/v1beta/models?key=#{api_key}")

request = Net::HTTP::Get.new(uri)

begin
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  if response.code == '200'
    result = JSON.parse(response.body)
    puts "Available models:"
    puts ""
    
    result['models'].each do |model|
      name = model['name']
      display_name = model['displayName']
      supported_methods = model['supportedGenerationMethods']
      
      if supported_methods&.include?('generateContent')
        puts "✓ #{name}"
        puts "  Display: #{display_name}"
        puts "  Methods: #{supported_methods.join(', ')}"
        puts ""
      end
    end
  else
    puts "❌ Error: #{response.body}"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end
