require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')

puts "Deleting document 48 and its entities..."
db.execute('DELETE FROM entities WHERE document_id = 48')
db.execute('DELETE FROM documents WHERE id = 48')

puts "✓ Document 48 deleted"
puts ""
puts "Now refresh your browser and view document 45 instead."
puts "Document 45 has the clean 14 entities you want!"

db.close
