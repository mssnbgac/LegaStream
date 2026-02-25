#!/usr/bin/env ruby
# Test script to verify the entity saving bug fix

require 'sqlite3'
require 'json'

puts "=" * 80
puts "TESTING ENTITY SAVING FIX"
puts "=" * 80
puts ""

# Get the latest document
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

unless doc
  puts "❌ No documents found. Please upload a document first."
  db.close
  exit 1
end

puts "Testing with document: #{doc['filename']}"
puts "Document ID: #{doc['id']}"
puts ""

# Parse analysis results
if doc['analysis_results']
  results = JSON.parse(doc['analysis_results'])
  
  entities_extracted = results['entities_extracted']
  entity_breakdown = results['entity_breakdown'] || {}
  
  puts "Analysis Results:"
  puts "  Total entities extracted by AI: #{entities_extracted}"
  puts ""
  
  if entity_breakdown.any?
    puts "  Breakdown:"
    entity_breakdown.each do |type, count|
      puts "    - #{count} #{type}"
    end
    puts ""
  end
end

# Count entities in database
entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc['id']])
entities_in_db = entities.length

puts "Entities saved to database: #{entities_in_db}"
puts ""

# Calculate success rate
if entities_extracted && entities_extracted > 0
  success_rate = (entities_in_db.to_f / entities_extracted * 100).round(1)
  
  puts "=" * 80
  puts "RESULTS"
  puts "=" * 80
  puts ""
  
  if success_rate >= 95
    puts "✅ SUCCESS! #{success_rate}% of entities saved correctly"
    puts ""
    puts "The bug is FIXED! All entities are being saved to the database."
  elsif success_rate >= 80
    puts "⚠️  PARTIAL SUCCESS: #{success_rate}% of entities saved"
    puts ""
    puts "Most entities are saving, but some are still missing."
    puts "This might be due to:"
    puts "  - Duplicate detection working correctly (removing actual duplicates)"
    puts "  - Some entities failing validation"
  else
    puts "❌ FAILURE: Only #{success_rate}% of entities saved"
    puts ""
    puts "The bug is NOT fixed. Entities are still being lost."
    puts ""
    puts "Possible causes:"
    puts "  - Server not restarted after fix"
    puts "  - Different bug causing entity loss"
    puts "  - SQL errors with special characters"
  end
  
  puts ""
  puts "Breakdown by type:"
  
  # Group database entities by type
  db_by_type = entities.group_by { |e| e['entity_type'] }
  
  # Compare with expected breakdown
  if entity_breakdown.any?
    entity_breakdown.each do |type, expected_count|
      type_upper = type.upcase.gsub('IES', 'Y').gsub('ES', 'E').gsub('S', '')
      type_upper = 'PARTY' if type == 'parties'
      type_upper = 'ADDRESS' if type == 'addresses'
      type_upper = 'DATE' if type == 'dates'
      type_upper = 'AMOUNT' if type == 'amounts'
      type_upper = 'OBLIGATION' if type == 'obligations'
      type_upper = 'CLAUSE' if type == 'clauses'
      type_upper = 'JURISDICTION' if type == 'jurisdictions'
      type_upper = 'TERM' if type == 'terms'
      type_upper = 'CONDITION' if type == 'conditions'
      type_upper = 'PENALTY' if type == 'penalties'
      
      actual_count = db_by_type[type_upper]&.length || 0
      
      status = if actual_count == expected_count
        "✅"
      elsif actual_count >= expected_count * 0.8
        "⚠️ "
      else
        "❌"
      end
      
      puts "  #{status} #{type}: Expected #{expected_count}, Got #{actual_count}"
    end
  end
  
  puts ""
  puts "=" * 80
  
  if success_rate >= 95
    puts ""
    puts "Next steps:"
    puts "  1. ✅ Bug is fixed!"
    puts "  2. Test with more documents to confirm"
    puts "  3. Deploy to production (Render)"
    puts ""
  else
    puts ""
    puts "Next steps:"
    puts "  1. Restart the server: ./stop.ps1 && ./start.ps1"
    puts "  2. Upload a NEW document (don't reanalyze old ones)"
    puts "  3. Run this test again"
    puts ""
  end
else
  puts "⚠️  Cannot calculate success rate - no analysis results found"
end

db.close
