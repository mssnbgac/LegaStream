require 'sqlite3'
require 'json'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "=" * 80
puts "DOCUMENT 45 - THE PERFECT EXTRACTION"
puts "=" * 80
puts ""

doc = db.execute('SELECT * FROM documents WHERE id = 45').first
entities = db.execute('SELECT * FROM entities WHERE document_id = 45 ORDER BY entity_type, id')

puts "Total entities: #{entities.length}"
puts ""

# Group by type
grouped = entities.group_by { |e| e['entity_type'] }

grouped.each do |type, ents|
  puts "#{type} (#{ents.length}):"
  ents.each do |e|
    puts "  - \"#{e['entity_value']}\" (#{e['context']}) [#{(e['confidence'] * 100).to_i}%]"
  end
  puts ""
end

puts "=" * 80
puts "KEY CHARACTERISTICS OF PERFECT EXTRACTION:"
puts "=" * 80
puts "1. Clean entity values (no fragments like 'is made between')"
puts "2. Both parties extracted (Acme Corporation AND John Smith)"
puts "3. Proper context descriptions"
puts "4. High confidence (90-95%)"
puts "5. No duplicate or overlapping entities"
puts ""

db.close
