require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Find documents with exactly 8 entities
docs = db.execute("SELECT d.id, d.filename, COUNT(e.id) as entity_count 
                   FROM documents d 
                   LEFT JOIN entities e ON d.id = e.document_id 
                   GROUP BY d.id 
                   HAVING entity_count = 8
                   ORDER BY d.id DESC")

if docs.any?
  docs.each do |doc|
    puts "Document #{doc['id']}: #{doc['filename']} (#{doc['entity_count']} entities)"
    puts "=" * 80
    
    # Get all entities
    entities = db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY entity_type, entity_value", [doc['id']])
    
    entities.each do |e|
      puts "#{e['entity_type']}: \"#{e['entity_value']}\" (#{(e['confidence'] * 100).round}%)"
    end
    
    puts "\n"
    
    # Check for same value, different types
    by_value = entities.group_by { |e| e['entity_value'] }
    duplicates = by_value.select { |v, ents| ents.length > 1 }
    
    if duplicates.any?
      puts "⚠️  SAME VALUE, DIFFERENT TYPES:"
      duplicates.each do |value, ents|
        types = ents.map { |e| e['entity_type'] }.uniq
        puts "  \"#{value}\" appears as: #{types.join(', ')}"
      end
    end
    
    puts "\n" + "=" * 80 + "\n"
  end
else
  puts "No documents with exactly 8 entities found"
end

db.close
