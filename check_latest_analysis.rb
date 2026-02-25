require 'sqlite3'
require 'json'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "=" * 80
puts "CHECKING LATEST DOCUMENT ANALYSIS"
puts "=" * 80
puts ""

# Get latest document
doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

if doc
  puts "Document ID: #{doc['id']}"
  puts "Filename: #{doc['filename']}"
  puts "Status: #{doc['status']}"
  puts ""
  
  # Get analysis results
  if doc['analysis_results']
    results = JSON.parse(doc['analysis_results'])
    puts "Analysis Results:"
    puts "  Entities Extracted: #{results['entities_extracted']}"
    puts "  Using Real AI: #{results['using_real_ai']}"
    puts "  Confidence: #{results['confidence_score']}%"
    puts ""
  end
  
  # Get entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY id", [doc['id']])
  
  puts "Entities in Database: #{entities.length}"
  puts ""
  
  # Group by type
  by_type = entities.group_by { |e| e['entity_type'] }
  
  by_type.each do |type, ents|
    puts "#{type} (#{ents.length}):"
    ents.each do |e|
      puts "  - #{e['entity_value']}"
      puts "    Context: #{e['context']}"
      puts "    Confidence: #{(e['confidence'] * 100).to_i}%"
    end
    puts ""
  end
  
  # Check what's missing
  puts "=" * 80
  puts "MISSING ENTITIES (mentioned in summary but not extracted):"
  puts "=" * 80
  
  summary = doc['summary'] || ''
  
  missing = []
  missing << "Acme Corporation (PARTY)" unless entities.any? { |e| e['entity_value'].include?('Acme') }
  missing << "$5,000 penalty (PENALTY)" unless entities.any? { |e| e['entity_value'].include?('5,000') || e['entity_value'].include?('5000') }
  missing << "24-month term (TERM)" unless entities.any? { |e| e['entity_value'].include?('24') || e['entity_value'].include?('month') }
  missing << "30 days notice (CLAUSE)" unless entities.any? { |e| e['entity_value'].include?('30') && e['entity_value'].include?('days') }
  missing << "background check (CONDITION)" unless entities.any? { |e| e['entity_value'].downcase.include?('background') }
  
  if missing.any?
    missing.each { |m| puts "  ❌ #{m}" }
  else
    puts "  ✅ All entities extracted correctly!"
  end
  
else
  puts "No documents found"
end

db.close
