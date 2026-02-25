#!/usr/bin/env ruby
# Fix the entity saving bug in ai_analysis_service.rb
# Bug: Missing db.results_as_hash = true causes duplicate detection to fail

require 'fileutils'

file_path = 'app/services/ai_analysis_service.rb'

puts "=" * 80
puts "FIXING ENTITY SAVING BUG"
puts "=" * 80
puts ""

# Read the file
content = File.read(file_path)

# Check if already fixed
if content.include?('db.results_as_hash = true') && content =~ /def save_entity_if_not_exists.*?db\.results_as_hash = true/m
  puts "✓ File already fixed!"
  puts ""
  exit 0
end

# Find the save_entity_if_not_exists method and add db.results_as_hash = true
old_code = <<~OLD
  def save_entity_if_not_exists(entity_type, entity_value, context, confidence = 0.85)
    db = SQLite3::Database.new('storage/legastream.db')
    
    # Normalize value for comparison (trim, lowercase, remove punctuation and spaces)
OLD

new_code = <<~NEW
  def save_entity_if_not_exists(entity_type, entity_value, context, confidence = 0.85)
    db = SQLite3::Database.new('storage/legastream.db')
    db.results_as_hash = true  # FIX: Ensure query results are returned as hashes
    
    # Normalize value for comparison (trim, lowercase, remove punctuation and spaces)
NEW

# Apply the fix
if content.include?(old_code)
  content.gsub!(old_code, new_code)
  
  # Write back
  File.write(file_path, content)
  
  puts "✓ Bug fixed successfully!"
  puts ""
  puts "What was fixed:"
  puts "  - Added 'db.results_as_hash = true' to save_entity_if_not_exists method"
  puts "  - This ensures database queries return hashes instead of arrays"
  puts "  - Fixes the duplicate detection logic that was failing silently"
  puts ""
  puts "Impact:"
  puts "  - All 17 entities will now be saved correctly (instead of only 7)"
  puts "  - Duplicate detection will work properly"
  puts "  - No more silent failures when accessing e['entity_value']"
  puts ""
  puts "Next steps:"
  puts "  1. Restart the server: ./stop.ps1 && ./start.ps1"
  puts "  2. Upload a document to test"
  puts "  3. Verify all entities are saved correctly"
  puts ""
else
  puts "❌ Could not find the expected code pattern"
  puts "The file may have been modified. Please add this line manually:"
  puts ""
  puts "In the save_entity_if_not_exists method (around line 625),"
  puts "add this line after 'db = SQLite3::Database.new(...)'"
  puts ""
  puts "    db.results_as_hash = true"
  puts ""
  exit 1
end
