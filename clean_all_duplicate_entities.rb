require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "Cleaning ALL duplicate entities from database..."
puts "=" * 80

# Get all documents
docs = db.execute("SELECT id, filename FROM documents ORDER BY id")

total_removed = 0
docs_cleaned = 0

docs.each do |doc|
  doc_id = doc['id']
  
  # Get all entities for this document
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY id", [doc_id])
  
  next if entities.empty?
  
  # Track seen entities by normalized value (ignoring type differences for now)
  seen = {}
  to_delete = []
  
  entities.each do |entity|
    # Normalize: lowercase, remove punctuation and spaces
    normalized = entity['entity_value'].to_s.strip.downcase.gsub(/[[:punct:]\s]/, '')
    
    # Create key with type AND normalized value
    key = "#{entity['entity_type']}:#{normalized}"
    
    if seen[key]
      # This is a duplicate - mark for deletion (keep first occurrence)
      to_delete << entity['id']
    else
      # First occurrence - keep it
      seen[key] = entity['id']
    end
  end
  
  # Also check for same value with different types (cross-type duplicates)
  by_normalized_value = entities.group_by do |e|
    e['entity_value'].to_s.strip.downcase.gsub(/[[:punct:]\s]/, '')
  end
  
  cross_type_dups = by_normalized_value.select { |v, ents| ents.length > 1 && ents.map { |e| e['entity_type'] }.uniq.length > 1 }
  
  cross_type_dups.each do |value, ents|
    # Keep only the first one, delete the rest
    ents[1..-1].each do |ent|
      to_delete << ent['id'] unless to_delete.include?(ent['id'])
    end
  end
  
  # Delete duplicates
  if to_delete.any?
    puts "\nDocument #{doc_id}: #{doc['filename']}"
    puts "  Removing #{to_delete.length} duplicate entities"
    
    to_delete.uniq.each do |entity_id|
      db.execute("DELETE FROM entities WHERE id = ?", [entity_id])
    end
    
    total_removed += to_delete.uniq.length
    docs_cleaned += 1
  end
end

puts "\n" + "=" * 80
puts "✅ Cleaned #{docs_cleaned} documents"
puts "✅ Removed #{total_removed} duplicate entities total"
puts "=" * 80

db.close
