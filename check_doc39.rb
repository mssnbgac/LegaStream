require 'sqlite3'
require 'json'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc_id = 39

puts "=" * 80
puts "CHECKING DOCUMENT ID #{doc_id}"
puts "=" * 80
puts ""

doc = db.execute("SELECT * FROM documents WHERE id = ?", [doc_id]).first

if doc
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
  
  puts "Summary:"
  puts doc['summary']
  puts ""
  puts "=" * 80
  
  # Get entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc_id])
  
  puts "Entities in Database: #{entities.length}"
  puts "=" * 80
  puts ""
  
  entities.each do |e|
    puts "#{e['entity_type']}: #{e['entity_value']}"
    puts "  Context: #{e['context']}"
    puts "  Confidence: #{(e['confidence'] * 100).to_i}%"
    puts ""
  end
  
  if entities.length < 8
    puts "=" * 80
    puts "PROBLEM: Analysis says #{results['entities_extracted']} entities but only #{entities.length} in database!"
    puts "=" * 80
    puts ""
    puts "This means 7 entities were extracted but not saved."
    puts "Possible causes:"
    puts "  1. save_entity_if_not_exists is filtering them as duplicates"
    puts "  2. Database error during save"
    puts "  3. Entities are being lost during deduplication"
  end
end

db.close
