require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Get all documents
docs = db.execute("SELECT id FROM documents")

total_removed = 0

docs.each do |doc|
  doc_id = doc['id']
  
  # Get all entities for this document
  entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY id", [doc_id])
  
  # Group by type + normalized value
  seen = {}
  to_delete = []
  
  entities.each do |entity|
    # Normalize: lowercase, remove punctuation
    normalized = "#{entity['entity_type']}:#{entity['entity_value'].downcase.gsub(/[[:punct:]]/, '')}"
    
    if seen[normalized]
      # This is a duplicate - mark for deletion
      to_delete << entity['id']
    else
      # First occurrence - keep it
      seen[normalized] = entity['id']
    end
  end
  
  # Delete duplicates
  if to_delete.any?
    puts "Document #{doc_id}: Removing #{to_delete.length} duplicate entities"
    to_delete.each do |entity_id|
      db.execute("DELETE FROM entities WHERE id = ?", [entity_id])
    end
    total_removed += to_delete.length
  end
end

puts "\n" + "=" * 60
puts "✅ Removed #{total_removed} duplicate entities total"
puts "=" * 60

db.close
