#!/usr/bin/env ruby
require 'sqlite3'
require 'dotenv/load'
require_relative 'app/services/ai_analysis_service'

puts "=" * 80
puts "FIXING DOCUMENT 45 - REANALYZING WITH GEMINI AI"
puts "=" * 80
puts ""

# Step 1: Delete old entities
db = SQLite3::Database.new('storage/legastream.db')
deleted = db.execute("DELETE FROM entities WHERE document_id = 45")
puts "✓ Deleted #{db.changes} old entities"

# Step 2: Reset document status
db.execute("UPDATE documents SET status = 'uploaded', analysis_results = NULL WHERE id = 45")
puts "✓ Reset document status"
db.close

puts ""
puts "Starting AI analysis with Gemini..."
puts ""

# Step 3: Analyze with Gemini AI
service = AIAnalysisService.new(45)
result = service.analyze

puts ""
puts "=" * 80
puts "RESULTS"
puts "=" * 80
puts ""

if result[:success]
  puts "✅ SUCCESS!"
  puts ""
  puts "Entities extracted by AI: #{result[:entities].length}"
  
  # Check database
  db = SQLite3::Database.new('storage/legastream.db')
  db.results_as_hash = true
  saved_entities = db.execute("SELECT * FROM entities WHERE document_id = 45")
  db.close
  
  puts "Entities saved to database: #{saved_entities.length}"
  puts ""
  
  if saved_entities.length == result[:entities].length
    puts "✅ ALL ENTITIES SAVED CORRECTLY!"
  else
    puts "⚠️  Some entities missing: #{result[:entities].length - saved_entities.length} not saved"
  end
  
  puts ""
  puts "Now refresh your browser and view the document!"
  puts "You should see all #{saved_entities.length} entities in the modal."
else
  puts "❌ FAILED: #{result[:error]}"
end

puts ""
puts "=" * 80
