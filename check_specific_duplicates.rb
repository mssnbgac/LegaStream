require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Get all documents
docs = db.execute("SELECT id, filename FROM documents ORDER BY id DESC LIMIT 5")

puts "Recent Documents:"
puts "=" * 80

docs.each do |doc|
  puts "\nDocument #{doc['id']}: #{doc['filename']}"
  puts "-" * 80
  
  # Get all entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, entity_value", [doc['id']])
  
  puts "Total entities: #{entities.length}"
  
  # Check for exact duplicates (same type + value)
  duplicates = entities.group_by { |e| "#{e['entity_type']}:#{e['entity_value']}" }
                       .select { |k, v| v.length > 1 }
  
  if duplicates.any?
    puts "\n⚠️  DUPLICATES FOUND: #{duplicates.length} unique values with duplicates"
    duplicates.first(3).each do |key, dups|
      type, value = key.split(':', 2)
      puts "  #{type}: \"#{value}\" (appears #{dups.length} times)"
    end
    
    # Show total duplicate count
    total_dups = duplicates.values.sum { |v| v.length - 1 }
    puts "\n  Total duplicate entries: #{total_dups}"
  else
    puts "✅ No duplicates"
  end
end

db.close
