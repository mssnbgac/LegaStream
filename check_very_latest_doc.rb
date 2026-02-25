require 'sqlite3'
require 'json'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "=" * 80
puts "CHECKING VERY LATEST DOCUMENT"
puts "=" * 80
puts ""

# Get latest document
doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

if doc
  puts "Document ID: #{doc['id']}"
  puts "Filename: #{doc['filename']}"
  puts "Status: #{doc['status']}"
  puts "Created: #{doc['created_at']}"
  puts ""
  
  # Get analysis results
  if doc['analysis_results']
    results = JSON.parse(doc['analysis_results'])
    puts "Analysis Results:"
    puts "  Entities Extracted: #{results['entities_extracted']}"
    puts "  Using Real AI: #{results['using_real_ai']}"
    puts "  Confidence: #{results['confidence_score']}%"
    puts ""
    
    puts "Summary:"
    puts doc['summary']
    puts ""
  end
  
  # Get entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, id", [doc['id']])
  
  puts "=" * 80
  puts "Entities in Database: #{entities.length}"
  puts "=" * 80
  puts ""
  
  if entities.any?
    # Group by type
    by_type = entities.group_by { |e| e['entity_type'] }
    
    by_type.each do |type, ents|
      puts "#{type} (#{ents.length}):"
      ents.each do |e|
        puts "  - #{e['entity_value']}"
        puts "    Context: #{e['context']}"
        puts "    Confidence: #{(e['confidence'] * 100).to_i}%"
        puts "    ID: #{e['id']}"
      end
      puts ""
    end
  else
    puts "❌ NO ENTITIES IN DATABASE!"
    puts ""
    puts "This means entities were extracted but not saved."
    puts "Check server logs for errors in save_entity_if_not_exists method."
  end
  
  # Check what should be there based on summary
  summary = doc['summary'] || ''
  
  puts "=" * 80
  puts "ENTITIES MENTIONED IN SUMMARY:"
  puts "=" * 80
  
  # Extract key info from summary
  if summary.include?('BrightPath')
    puts "  - BrightPath Solutions Limited (PARTY)"
  end
  
  if summary.include?('Samuel Okoye')
    puts "  - Samuel Okoye (PARTY)"
  end
  
  if summary.include?('February 10')
    puts "  - February 10, 2026 (DATE)"
  end
  
  if summary.include?('May 10')
    puts "  - May 10, 2026 (DATE)"
  end
  
  if summary.include?('₦500,000')
    puts "  - ₦500,000 (AMOUNT)"
  end
  
  if summary.include?('monthly reports')
    puts "  - Submit monthly reports (OBLIGATION)"
  end
  
  if summary.include?('confidentiality')
    puts "  - Maintain confidentiality (OBLIGATION)"
  end
  
  if summary.include?('14 days')
    puts "  - 14 days' written notice (CLAUSE/CONDITION)"
  end
  
else
  puts "No documents found"
end

db.close
