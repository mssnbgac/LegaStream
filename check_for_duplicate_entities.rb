require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Get the latest document
doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

if doc
  puts "Checking Document #{doc['id']}: #{doc['filename']}"
  puts "=" * 60
  
  # Get all entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, entity_value", [doc['id']])
  
  puts "Total entities: #{entities.length}"
  puts ""
  
  # Check for duplicates (same type + value)
  duplicates = entities.group_by { |e| "#{e['entity_type']}:#{e['entity_value']}" }
                       .select { |k, v| v.length > 1 }
  
  if duplicates.any?
    puts "⚠️  DUPLICATES FOUND:"
    puts ""
    duplicates.each do |key, dups|
      type, value = key.split(':', 2)
      puts "#{type}: #{value}"
      puts "  Appears #{dups.length} times with IDs: #{dups.map { |d| d['id'] }.join(', ')}"
      puts ""
    end
  else
    puts "✅ No duplicates found - each entity is unique"
  end
  
  # Show entity breakdown
  puts ""
  puts "Entity Breakdown:"
  puts "-" * 60
  by_type = entities.group_by { |e| e['entity_type'] }
  by_type.each do |type, ents|
    puts "#{type}: #{ents.length} entities"
  end
else
  puts "No documents found"
end

db.close
