require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

docs = db.execute('SELECT id, original_filename, status FROM documents ORDER BY id DESC LIMIT 5')
puts 'Recent documents:'
docs.each { |d| puts "  ID #{d['id']}: #{d['original_filename']} (#{d['status']})" }

db.close
