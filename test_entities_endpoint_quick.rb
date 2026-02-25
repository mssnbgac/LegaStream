#!/usr/bin/env ruby
require 'net/http'
require 'json'

# Test the entities endpoint
uri = URI('http://localhost:6000/api/v1/documents/45/entities')

request = Net::HTTP::Get.new(uri)
request['Content-Type'] = 'application/json'

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

puts "Status: #{response.code}"
puts "Response:"
puts JSON.pretty_generate(JSON.parse(response.body))
