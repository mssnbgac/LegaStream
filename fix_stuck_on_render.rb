#!/usr/bin/env ruby
# Run this on Render Shell to fix stuck documents

require 'sqlite3'
require 'json'

puts "Connecting to database..."
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Find stuck documents
stuck = db.execute("SELECT id, filename, created_at FROM documents WHERE status = 'processing'")

if stuck.empty?
  puts "✅ No stuck documents found"
else
  puts "Found #{stuck.length} stuck document(s):"
  stuck.each do |doc|
    puts "  - ID #{doc['id']}: #{doc['filename']} (created #{doc['created_at']})"
  end
  
  puts "\nMarking as error so they can be retried..."
  db.execute("UPDATE documents SET status = 'error' WHERE status = 'processing'")
  puts "✅ Fixed #{stuck.length} document(s)"
  puts "\nYou can now:"
  puts "1. Delete these documents from the UI"
  puts "2. Upload them again"
  puts "3. Or click 'Analyze' to retry"
end

# Check API key
puts "\nChecking environment..."
if ENV['GEMINI_API_KEY']
  key = ENV['GEMINI_API_KEY']
  puts "✅ GEMINI_API_KEY is set: #{key[0..10]}..."
  
  if key == 'AIzaSyAYOIkIxZFvLuunEjQDN0YuJ-PVxnfWsk8'
    puts "✅ API key matches the working key"
  else
    puts "⚠️  API key is different from the working key"
    puts "   Expected: AIzaSyAYOIkIxZFvLuunEjQDN0YuJ-PVxnfWsk8"
    puts "   Current:  #{key}"
  end
else
  puts "❌ GEMINI_API_KEY not set!"
  puts "   Set it in Render Dashboard → Environment"
end

db.close
puts "\n✅ Done!"
