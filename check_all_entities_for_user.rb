require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Get the user who owns document 39
doc = db.execute("SELECT user_id FROM documents WHERE id = 39").first
user_id = doc['user_id']

puts "=" * 80
puts "ALL ENTITIES FOR USER #{user_id}"
puts "=" * 80
puts ""

# Get all documents for this user
docs = db.execute("SELECT id, filename FROM documents WHERE user_id = ? ORDER BY id", [user_id])

docs.each do |doc|
  entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc['id']])
  
  puts "Document #{doc['id']}: #{doc['filename']}"
  puts "  Entities: #{entities.length}"
  
  if entities.any?
    by_type = entities.group_by { |e| e['entity_type'] }
    by_type.each do |type, ents|
      puts "    #{type}: #{ents.length}"
    end
  end
  puts ""
end

db.close
