require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Find the rental agreement document
doc = db.execute("SELECT * FROM documents WHERE filename LIKE '%Rental%' OR filename LIKE '%rental%'").first

if doc
  puts "Found Document #{doc['id']}: #{doc['filename']}"
  puts "=" * 80
  
  # Get all entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, entity_value", [doc['id']])
  
  puts "Total entities in database: #{entities.length}"
  puts ""
  
  # Show all entities
  entities.each do |e|
    puts "#{e['entity_type']}: \"#{e['entity_value']}\" (#{(e['confidence'] * 100).round}%)"
  end
  
  puts "\n" + "=" * 80
  
  # Check for duplicates
  by_normalized = entities.group_by do |e|
    e['entity_value'].to_s.strip.downcase.gsub(/[[:punct:]\s]/, '')
  end
  
  duplicates = by_normalized.select { |v, ents| ents.length > 1 }
  
  if duplicates.any?
    puts "\n⚠️  DUPLICATES FOUND:"
    duplicates.each do |normalized, ents|
      puts "\nValue: \"#{ents.first['entity_value']}\""
      puts "Appears #{ents.length} times as:"
      ents.each do |e|
        puts "  - #{e['entity_type']} (#{(e['confidence'] * 100).round}% confidence, ID: #{e['id']})"
      end
    end
    
    # Calculate what should remain
    unique_count = by_normalized.keys.length
    puts "\n" + "=" * 80
    puts "Should have: #{unique_count} unique entities"
    puts "Currently has: #{entities.length} entities"
    puts "Need to remove: #{entities.length - unique_count} duplicates"
  else
    puts "✅ No duplicates found"
  end
else
  puts "Rental agreement document not found"
end

db.close
