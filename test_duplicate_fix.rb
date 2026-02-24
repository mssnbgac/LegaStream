#!/usr/bin/env ruby
require 'sqlite3'
require_relative 'app/services/ai_analysis_service'

puts "🧪 Testing Duplicate Entity Fix"
puts "=" * 60

# Get the latest document
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

unless doc
  puts "❌ No documents found. Please upload a document first."
  exit 1
end

doc_id = doc['id']
puts "📄 Testing with document ID: #{doc_id}"
puts "   Filename: #{doc['filename']}"
puts

# Delete existing entities for this document
puts "🗑️  Deleting existing entities..."
deleted = db.execute("DELETE FROM entities WHERE document_id = ?", [doc_id])
db.changes
puts "   Deleted #{db.changes} entities"
puts

# Run analysis
puts "🔬 Running AI analysis..."
analyzer = AIAnalysisService.new(doc_id)
result = analyzer.analyze

if result[:success]
  puts "✅ Analysis completed successfully"
  puts
  
  # Check entities in database
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, entity_value", [doc_id])
  
  puts "📊 Entities in Database:"
  puts "   Total: #{entities.length}"
  puts
  
  # Group by type
  grouped = entities.group_by { |e| e['entity_type'] }
  grouped.each do |type, ents|
    puts "   #{type} (#{ents.length}):"
    ents.each do |e|
      puts "     - #{e['entity_value']} (#{(e['confidence'] * 100).round}% confidence)"
    end
    puts
  end
  
  # Check for duplicates
  puts "🔍 Checking for duplicates..."
  duplicates = []
  entities.each_with_index do |e1, i|
    entities[(i+1)..-1].each do |e2|
      if e1['entity_type'] == e2['entity_type'] && 
         e1['entity_value'].downcase.strip == e2['entity_value'].downcase.strip
        duplicates << [e1['entity_type'], e1['entity_value']]
      end
    end
  end
  
  if duplicates.empty?
    puts "✅ NO DUPLICATES FOUND! Fix is working!"
  else
    puts "❌ Found #{duplicates.length} duplicates:"
    duplicates.each do |type, value|
      puts "   - #{type}: #{value}"
    end
  end
else
  puts "❌ Analysis failed: #{result[:error]}"
end

db.close
