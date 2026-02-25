#!/usr/bin/env ruby
# Reanalyze document 45 with detailed logging to see what AI extracts

require 'sqlite3'
require 'json'
require 'dotenv/load'  # Load environment variables
require_relative 'app/services/ai_analysis_service'

puts "=" * 80
puts "REANALYZING DOCUMENT 45 WITH DEBUG LOGGING"
puts "=" * 80
puts ""

# Get document info
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc = db.execute("SELECT * FROM documents WHERE id = 45").first

unless doc
  puts "❌ Document 45 not found"
  db.close
  exit 1
end

puts "Document: #{doc['filename']}"
puts "Current status: #{doc['status']}"
puts ""

# Delete existing entities for this document
puts "Deleting existing entities..."
deleted = db.execute("DELETE FROM entities WHERE document_id = 45")
puts "Deleted #{db.changes} entities"
puts ""

# Reset document status
db.execute("UPDATE documents SET status = 'uploaded', analysis_results = NULL WHERE id = 45")
puts "Reset document status to 'uploaded'"
puts ""

db.close

# Now analyze
puts "=" * 80
puts "STARTING ANALYSIS"
puts "=" * 80
puts ""

service = AIAnalysisService.new(45)
result = service.analyze

puts ""
puts "=" * 80
puts "ANALYSIS COMPLETE"
puts "=" * 80
puts ""

if result[:success]
  puts "✅ Analysis successful!"
  puts ""
  puts "Entities extracted by AI: #{result[:entities].length}"
  puts ""
  
  # Group by type
  by_type = result[:entities].group_by { |e| e['type'] || e[:type] }
  
  by_type.each do |type, ents|
    puts "#{type} (#{ents.length}):"
    ents.each do |e|
      value = e['value'] || e[:value]
      context = e['context'] || e[:context]
      confidence = e['confidence'] || e[:confidence]
      puts "  - #{value}"
      puts "    Context: #{context}"
      puts "    Confidence: #{(confidence * 100).to_i}%"
    end
    puts ""
  end
  
  # Check database
  puts "=" * 80
  puts "CHECKING DATABASE"
  puts "=" * 80
  puts ""
  
  db = SQLite3::Database.new('storage/legastream.db')
  db.results_as_hash = true
  
  saved_entities = db.execute("SELECT * FROM entities WHERE document_id = 45")
  puts "Entities saved to database: #{saved_entities.length}"
  puts ""
  
  if saved_entities.length < result[:entities].length
    puts "⚠️  WARNING: #{result[:entities].length - saved_entities.length} entities were NOT saved!"
    puts ""
    
    # Find which ones are missing
    saved_values = saved_entities.map { |e| e['entity_value'].downcase.gsub(/[[:punct:]\s]/, '') }
    
    result[:entities].each do |e|
      value = (e['value'] || e[:value]).to_s
      normalized = value.downcase.gsub(/[[:punct:]\s]/, '')
      
      unless saved_values.include?(normalized)
        puts "❌ MISSING: #{value} (#{e['type'] || e[:type]})"
      end
    end
  else
    puts "✅ All entities saved successfully!"
  end
  
  db.close
  
  # Show logs
  if result[:logs] && result[:logs].any?
    puts ""
    puts "=" * 80
    puts "ANALYSIS LOGS"
    puts "=" * 80
    puts ""
    
    result[:logs].each do |log|
      level_color = case log[:level]
      when 'error' then '❌'
      when 'warning' then '⚠️ '
      else 'ℹ️ '
      end
      
      puts "#{level_color} #{log[:message]}"
    end
  end
else
  puts "❌ Analysis failed: #{result[:error]}"
end

puts ""
puts "=" * 80
puts "DONE"
puts "=" * 80
