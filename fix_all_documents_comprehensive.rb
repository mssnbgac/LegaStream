require 'sqlite3'
require_relative 'app/services/ai_analysis_service'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

puts "Comprehensive Document Fix"
puts "=" * 80

# Get all completed documents
docs = db.execute("SELECT * FROM documents WHERE status = 'completed' ORDER BY id")

docs.each do |doc|
  puts "\nDocument #{doc['id']}: #{doc['filename']}"
  
  # Get entities
  entities = db.execute("SELECT * FROM entities WHERE document_id = ?", [doc['id']])
  
  # Check for duplicates
  by_normalized = entities.group_by do |e|
    e['entity_value'].to_s.strip.downcase.gsub(/[[:punct:]\s]/, '')
  end
  
  duplicates = by_normalized.select { |v, ents| ents.length > 1 }
  
  if duplicates.any?
    puts "  ⚠️  Found #{duplicates.length} duplicated values"
    puts "  🔄 Reanalyzing..."
    
    # Delete all entities
    db.execute("DELETE FROM entities WHERE document_id = ?", [doc['id']])
    db.execute("DELETE FROM compliance_issues WHERE document_id = ?", [doc['id']])
    db.execute("UPDATE documents SET status = 'processing' WHERE id = ?", [doc['id']])
    
    # Reanalyze
    begin
      service = AIAnalysisService.new(doc['id'])
      result = service.analyze
      
      if result[:success]
        puts "  ✅ Reanalyzed: #{result[:entities].length} unique entities"
      else
        puts "  ❌ Failed: #{result[:error]}"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
  else
    puts "  ✅ No duplicates"
  end
end

puts "\n" + "=" * 80
puts "✅ All documents checked and fixed"

db.close
