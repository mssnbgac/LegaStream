#!/usr/bin/env ruby
require 'sqlite3'
require 'time'

puts "=" * 70
puts "DEPLOYMENT VERIFICATION & CLEANUP TOOL"
puts "=" * 70
puts ""

# Connect to database
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Check all documents
documents = db.execute("SELECT id, filename, created_at, status FROM documents ORDER BY created_at DESC")

puts "📄 DOCUMENTS IN DATABASE:"
puts "-" * 70

if documents.empty?
  puts "No documents found. Database is clean!"
else
  documents.each_with_index do |doc, index|
    doc_id = doc['id']
    filename = doc['filename']
    created_at = doc['created_at']
    status = doc['status']
    
    # Count entities for this document
    entity_count = db.execute("SELECT COUNT(*) as count FROM entities WHERE document_id = ?", [doc_id]).first['count']
    party_count = db.execute("SELECT COUNT(*) as count FROM entities WHERE document_id = ? AND entity_type = 'PARTY'", [doc_id]).first['count']
    
    puts ""
    puts "[#{index + 1}] Document ID: #{doc_id}"
    puts "    Filename: #{filename}"
    puts "    Created: #{created_at}"
    puts "    Status: #{status}"
    puts "    Total Entities: #{entity_count}"
    puts "    PARTY Entities: #{party_count}"
    
    # Flag suspicious documents
    if party_count > 15
      puts "    ⚠️  WARNING: Too many parties (#{party_count}) - likely has false positives"
    end
    
    # Check for duplicates
    duplicates = db.execute(<<-SQL, [doc_id])
      SELECT entity_type, entity_value, COUNT(*) as count
      FROM entities
      WHERE document_id = ?
      GROUP BY entity_type, entity_value
      HAVING COUNT(*) > 1
    SQL
    
    if duplicates.any?
      puts "    ⚠️  WARNING: Has #{duplicates.length} duplicate entities"
    end
  end
end

puts ""
puts "=" * 70
puts "RECOMMENDATIONS:"
puts "=" * 70

if documents.any?
  puts ""
  puts "🗑️  DELETE ALL OLD DOCUMENTS:"
  puts "   1. Go to https://legastream.onrender.com"
  puts "   2. Delete ALL documents shown above"
  puts "   3. They contain old extraction results"
  puts ""
  puts "📤 UPLOAD FRESH DOCUMENT:"
  puts "   1. Wait for Render deployment to complete"
  puts "   2. Upload a NEW document"
  puts "   3. Verify clean results (no duplicates, no false positives)"
  puts ""
end

puts "✅ VERIFY DEPLOYMENT:"
puts "   1. Go to https://dashboard.render.com"
puts "   2. Check your 'legastream' service"
puts "   3. Look for 'Deploy succeeded' with commit: 03d0613"
puts "   4. Wait until status shows 'Live'"
puts ""

db.close

puts "=" * 70
puts "Script complete!"
puts "=" * 70
