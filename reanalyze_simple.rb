#!/usr/bin/env ruby
require 'sqlite3'
require 'dotenv/load'
require_relative 'app/services/ai_analysis_service'

puts "Reanalyzing document 45..."

# Delete existing entities
db = SQLite3::Database.new('storage/legastream.db')
db.execute("DELETE FROM entities WHERE document_id = 45")
db.execute("UPDATE documents SET status = 'uploaded', analysis_results = NULL WHERE id = 45")
db.close

# Analyze
service = AIAnalysisService.new(45)
result = service.analyze

if result[:success]
  puts "✅ Analysis complete!"
  puts "Entities extracted: #{result[:entities].length}"
  
  # Check database
  db = SQLite3::Database.new('storage/legastream.db')
  db.results_as_hash = true
  saved = db.execute("SELECT COUNT(*) as count FROM entities WHERE document_id = 45").first
  db.close
  
  puts "Entities saved: #{saved['count']}"
else
  puts "❌ Analysis failed: #{result[:error]}"
end
