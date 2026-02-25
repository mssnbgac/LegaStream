require 'sqlite3'

db = SQLite3::Database.new('storage/legastream.db')

puts "User table columns:"
puts "=" * 80

# Get table info
columns = db.execute("PRAGMA table_info(users)")

columns.each do |col|
  puts "#{col[1]} (#{col[2]})"
end

db.close
