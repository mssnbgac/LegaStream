require 'sqlite3'
require_relative 'app/services/ai_analysis_service'

db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

# Get the most recent document
doc = db.execute("SELECT * FROM documents ORDER BY id DESC LIMIT 1").first

if doc
  puts "Reanalyzing Document #{doc['id']}: #{doc['filename']}"
  puts "=" * 60
  
  # Delete existing entities
  deleted = db.execute("DELETE FROM entities WHERE document_id = ?", [doc['id']])
  puts "Deleted #{db.changes} existing entities"
  
  # Delete existing compliance issues
  db.execute("DELETE FROM compliance_issues WHERE document_id = ?", [doc['id']])
  
  # Update status to processing
  db.execute("UPDATE documents SET status = 'processing' WHERE id = ?", [doc['id']])
  
  db.close
  
  # Run analysis
  puts "\nRunning analysis with updated deduplication logic..."
  service = AIAnalysisService.new(doc['id'])
  result = service.analyze
  
  if result[:success]
    puts "\n✅ Analysis complete!"
    puts "Entities found: #{result[:entities].length}"
    puts "Using real AI: #{result[:using_real_ai]}"
    
    # Show entity breakdown
    by_type = result[:entities].group_by { |e| e[:type] || e['type'] }
    puts "\nEntity breakdown:"
    by_type.each do |type, ents|
      puts "  #{type}: #{ents.length}"
    end
  else
    puts "\n❌ Analysis failed: #{result[:error]}"
  end
else
  puts "No documents found"
end
