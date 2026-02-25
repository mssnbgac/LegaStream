require 'sqlite3'
require 'net/http'
require 'json'
require 'uri'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc_id = 39

puts "=" * 80
puts "RE-ANALYZING DOCUMENT #{doc_id}"
puts "=" * 80
puts ""

# Delete existing entities
db.execute("DELETE FROM entities WHERE document_id = ?", [doc_id])
puts "Deleted existing entities"
puts ""

# Get user token
doc = db.execute("SELECT user_id FROM documents WHERE id = ?", [doc_id]).first
user = db.execute("SELECT token FROM users WHERE id = ?", [doc['user_id']]).first

if user
  uri = URI("http://localhost:4567/api/v1/documents/#{doc_id}/analyze")
  
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{user['token']}"
  request['Content-Type'] = 'application/json'
  
  puts "Sending analysis request..."
  puts ""
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  puts "Response Code: #{response.code}"
  puts ""
  
  if response.code == '200'
    result = JSON.parse(response.body)
    
    puts "✅ Analysis complete!"
    puts ""
    puts "Results:"
    puts "  Entities Extracted: #{result['entities_extracted']}"
    puts "  Using Real AI: #{result['using_real_ai']}"
    puts "  Confidence: #{result['confidence_score']}%"
    puts ""
    
    # Wait a moment for database to update
    sleep 1
    
    # Check database
    entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc_id])
    puts "Entities in database: #{entities.length}"
    puts ""
    
    if entities.length < result['entities_extracted']
      puts "⚠️  WARNING: #{result['entities_extracted']} entities extracted but only #{entities.length} saved!"
      puts ""
      puts "Check server console for error messages."
    else
      puts "✅ All entities saved successfully!"
      puts ""
      
      by_type = entities.group_by { |e| e['entity_type'] }
      by_type.each do |type, ents|
        puts "#{type} (#{ents.length}):"
        ents.each do |e|
          puts "  - #{e['entity_value']}"
        end
      end
    end
    
  else
    puts "❌ Analysis failed"
    puts response.body
  end
else
  puts "❌ No user found"
end

db.close
