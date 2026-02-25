require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "=" * 80
puts "RECENT DOCUMENTS"
puts "=" * 80
puts ""

docs = db.execute("SELECT id, filename, status, created_at FROM documents ORDER BY id DESC LIMIT 10")

docs.each do |doc|
  puts "ID: #{doc['id']}"
  puts "  Filename: #{doc['filename']}"
  puts "  Status: #{doc['status']}"
  puts "  Created: #{doc['created_at']}"
  
  # Count entities
  count = db.execute("SELECT COUNT(*) as count FROM entities WHERE document_id = ?", [doc['id']]).first['count']
  puts "  Entities in DB: #{count}"
  puts ""
end

db.close
