require 'sqlite3'
require 'json'

# Get latest document ID
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc = db.execute("SELECT id, filename FROM documents ORDER BY id DESC LIMIT 1").first

if doc
  doc_id = doc['id']
  filename = doc['filename']
  
  puts "=" * 80
  puts "RE-ANALYZING DOCUMENT WITH VERBOSE LOGGING"
  puts "=" * 80
  puts "Document ID: #{doc_id}"
  puts "Filename: #{filename}"
  puts ""
  
  # Delete existing entities
  deleted = db.execute("DELETE FROM entities WHERE document_id = ?", [doc_id])
  puts "Deleted existing entities"
  puts ""
  
  # Trigger re-analysis via API
  require 'net/http'
  require 'uri'
  
  # Get user token (assuming latest user)
  user = db.execute("SELECT * FROM users ORDER BY id DESC LIMIT 1").first
  
  if user
    puts "Using user: #{user['email']}"
    puts ""
    
    uri = URI("http://localhost:4567/api/v1/documents/#{doc_id}/analyze")
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{user['auth_token']}"
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
      
      # Check database again
      entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc_id])
      puts "Entities in database: #{entities.length}"
      puts ""
      
      # Group by type
      by_type = entities.group_by { |e| e['entity_type'] }
      
      by_type.each do |type, ents|
        puts "#{type} (#{ents.length}):"
        ents.each do |e|
          puts "  - #{e['entity_value']}"
        end
      end
      
    else
      puts "❌ Analysis failed"
      puts response.body
    end
    
  else
    puts "❌ No user found"
  end
  
else
  puts "❌ No documents found"
end

db.close
