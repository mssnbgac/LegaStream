require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Find documents with 8 entities that have duplicates
docs = db.execute("SELECT d.id, d.filename, COUNT(e.id) as entity_count 
                   FROM documents d 
                   LEFT JOIN entities e ON d.id = e.document_id 
                   GROUP BY d.id 
                   ORDER BY d.id DESC
                   LIMIT 10")

puts "Recent documents:"
puts "=" * 80

docs.each do |doc|
  next if doc['entity_count'] == 0
  
  puts "\nDocument #{doc['id']}: #{doc['filename']}"
  puts "  Entities: #{doc['entity_count']}"
  
  # Check for duplicates
  entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc['id']])
  
  by_normalized = entities.group_by do |e|
    e['entity_value'].to_s.strip.downcase.gsub(/[[:punct:]\s]/, '')
  end
  
  duplicates = by_normalized.select { |v, ents| ents.length > 1 }
  
  if duplicates.any?
    puts "  ⚠️  HAS DUPLICATES: #{duplicates.length} values duplicated"
  end
end

db.close
