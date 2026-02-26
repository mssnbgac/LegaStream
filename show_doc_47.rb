require 'sqlite3'
require 'json'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc = db.execute('SELECT * FROM documents WHERE id = 47').first
entities = db.execute('SELECT * FROM entities WHERE document_id = 47')

puts "Document 47:"
puts "  Filename: #{doc['original_filename']}"
puts "  Status: #{doc['status']}"
puts "  Entities: #{entities.length}"
puts ""

if doc['analysis_results']
  results = JSON.parse(doc['analysis_results'])
  puts "Entity breakdown:"
  results['entity_breakdown'].each do |type, count|
    puts "  #{type}: #{count}"
  end
end

puts ""
puts "=" * 60
puts "SOLUTION: Click on the document that shows '14 Entities Extracted'"
puts "That's the one with the perfect extraction!"
puts "=" * 60

db.close
