#!/usr/bin/env ruby
require 'sqlite3'
require 'dotenv/load'
require_relative 'app/services/ai_analysis_service'

puts "=" * 80
puts "FIXING DOCUMENT 47 - REANALYZING WITH ENHANCED PROMPT"
puts "=" * 80
puts ""

# Step 1: Delete old entities
db = SQLite3::Database.new('storage/legastream.db')
deleted = db.execute("DELETE FROM entities WHERE document_id = 47")
puts "✓ Deleted #{db.changes} old entities"

# Step 2: Reset document status
db.execute("UPDATE documents SET status = 'uploaded', analysis_results = NULL WHERE id = 47")
puts "✓ Reset document status"
db.close

puts ""
puts "Starting AI analysis with ENHANCED prompt..."
puts ""

# Step 3: Analyze with enhanced Gemini AI
service = AIAnalysisService.new(47)
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
  saved_entities = db.execute("SELECT * FROM entities WHERE document_id = 47")
  
  # Group by type
  grouped = saved_entities.group_by { |e| e['entity_type'] }
  
  puts "Entities saved to database: #{saved_entities.length}"
  puts ""
  puts "Breakdown:"
  grouped.each do |type, ents|
    puts "  #{type}: #{ents.length}"
  end
  
  db.close
  
  puts ""
  if saved_entities.length == result[:entities].length
    puts "✅ ALL ENTITIES SAVED CORRECTLY!"
  else
    puts "⚠️  Some entities missing: #{result[:entities].length - saved_entities.length} not saved"
  end
  
  puts ""
  puts "Now refresh your browser and view document 47!"
  puts "It should now have clean extraction like document 45."
else
  puts "❌ FAILED: #{result[:error]}"
end

puts ""
puts "=" * 80
