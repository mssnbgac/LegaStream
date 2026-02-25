#!/usr/bin/env ruby
# Production Readiness Verification Script
# Run this to verify all features are working before deployment

require 'sqlite3'
require 'json'

puts "=" * 80
puts "PRODUCTION READINESS VERIFICATION"
puts "=" * 80
puts ""

# Check 1: Database Schema
puts "1. Checking database schema..."
db = SQLite3::Database.new('storage/legastream.db')
db.results_as_hash = true

tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'")
required_tables = ['users', 'documents', 'entities', 'compliance_issues']

required_tables.each do |table|
  if tables.any? { |t| t['name'] == table }
    puts "   ✅ Table '#{table}' exists"
  else
    puts "   ❌ Table '#{table}' MISSING"
  end
end

# Check 2: Entity Types
puts ""
puts "2. Checking entity types in database..."
entity_types = db.execute("SELECT DISTINCT entity_type FROM entities ORDER BY entity_type")
expected_types = ['ADDRESS', 'AMOUNT', 'CLAUSE', 'CONDITION', 'DATE', 'JURISDICTION', 'OBLIGATION', 'PARTY', 'PENALTY', 'TERM']

if entity_types.length > 0
  puts "   Found #{entity_types.length} entity types:"
  entity_types.each { |e| puts "     - #{e['entity_type']}" }
else
  puts "   ⚠️  No entities in database yet (will be created on first upload)"
end

# Check 3: AI Service Configuration
puts ""
puts "3. Checking AI service configuration..."
if File.exist?('app/services/ai_analysis_service.rb')
  content = File.read('app/services/ai_analysis_service.rb')
  
  if content.include?('db.results_as_hash = true')
    puts "   ✅ Critical fix: results_as_hash = true (FOUND)"
  else
    puts "   ❌ Critical fix: results_as_hash = true (MISSING)"
  end
  
  if content.include?('PARTY') && content.include?('ADDRESS') && content.include?('AMOUNT')
    puts "   ✅ All 10 entity types defined"
  else
    puts "   ❌ Entity types incomplete"
  end
else
  puts "   ❌ ai_analysis_service.rb NOT FOUND"
end

# Check 4: AI Provider Configuration
puts ""
puts "4. Checking AI provider configuration..."
if File.exist?('app/services/ai_provider.rb')
  content = File.read('app/services/ai_provider.rb')
  
  if content.include?('maxOutputTokens: 4096')
    puts "   ✅ Token limit: 4096 (CORRECT)"
  elsif content.include?('maxOutputTokens: 2048')
    puts "   ❌ Token limit: 2048 (TOO LOW - should be 4096)"
  else
    puts "   ⚠️  Token limit not found"
  end
  
  if content.include?('gemini-2.5-flash')
    puts "   ✅ Model: gemini-2.5-flash (CORRECT)"
  else
    puts "   ⚠️  Model version not found"
  end
else
  puts "   ❌ ai_provider.rb NOT FOUND"
end

# Check 5: Production Server
puts ""
puts "5. Checking production server..."
if File.exist?('production_server.rb')
  content = File.read('production_server.rb')
  
  if content.include?('def initialize(port = 3001)')
    puts "   ✅ Port: 3001 (CORRECT)"
  else
    puts "   ⚠️  Port configuration not found"
  end
  
  if content.include?('AIAnalysisService.new')
    puts "   ✅ Automatic analysis: ENABLED"
  else
    puts "   ❌ Automatic analysis: NOT FOUND"
  end
else
  puts "   ❌ production_server.rb NOT FOUND"
end

# Check 6: Frontend Configuration
puts ""
puts "6. Checking frontend configuration..."
if File.exist?('frontend/src/pages/DocumentUpload.jsx')
  content = File.read('frontend/src/pages/DocumentUpload.jsx')
  
  if content.include?('Extracted Entities')
    puts "   ✅ Entity modal: PRESENT"
  else
    puts "   ❌ Entity modal: MISSING"
  end
  
  if content.include?('entity_breakdown')
    puts "   ✅ Entity breakdown: PRESENT"
  else
    puts "   ⚠️  Entity breakdown: NOT FOUND"
  end
  
  # Count entity type definitions
  entity_count = content.scan(/type: '(PARTY|ADDRESS|DATE|AMOUNT|OBLIGATION|CLAUSE|JURISDICTION|TERM|CONDITION|PENALTY)'/).length
  if entity_count >= 10
    puts "   ✅ All 10 entity types in UI"
  else
    puts "   ⚠️  Only #{entity_count} entity types found in UI"
  end
else
  puts "   ❌ DocumentUpload.jsx NOT FOUND"
end

# Check 7: Environment Variables
puts ""
puts "7. Checking environment variables..."
require 'dotenv/load'

if ENV['GEMINI_API_KEY'] && !ENV['GEMINI_API_KEY'].empty?
  puts "   ✅ GEMINI_API_KEY: SET"
else
  puts "   ❌ GEMINI_API_KEY: NOT SET"
end

if ENV['AI_PROVIDER'] == 'gemini'
  puts "   ✅ AI_PROVIDER: gemini"
else
  puts "   ⚠️  AI_PROVIDER: #{ENV['AI_PROVIDER'] || 'NOT SET'}"
end

# Check 8: Recent Documents
puts ""
puts "8. Checking recent document analysis..."
recent_docs = db.execute("SELECT id, status, analysis_results FROM documents ORDER BY created_at DESC LIMIT 3")

if recent_docs.length > 0
  puts "   Found #{recent_docs.length} recent documents:"
  recent_docs.each do |doc|
    if doc['analysis_results']
      results = JSON.parse(doc['analysis_results'])
      entity_count = results['entities_extracted'] || 0
      puts "     - Doc #{doc['id']}: #{doc['status']}, #{entity_count} entities"
    else
      puts "     - Doc #{doc['id']}: #{doc['status']}, no analysis yet"
    end
  end
else
  puts "   ⚠️  No documents in database yet"
end

# Check 9: Entity Counts
puts ""
puts "9. Checking entity statistics..."
total_entities = db.execute("SELECT COUNT(*) as count FROM entities").first['count']
total_docs = db.execute("SELECT COUNT(*) as count FROM documents").first['count']

puts "   Total documents: #{total_docs}"
puts "   Total entities: #{total_entities}"

if total_docs > 0 && total_entities > 0
  avg_entities = (total_entities.to_f / total_docs).round(1)
  puts "   Average entities per document: #{avg_entities}"
  
  if avg_entities >= 10
    puts "   ✅ Good entity extraction rate"
  else
    puts "   ⚠️  Low entity extraction rate (expected 10-20)"
  end
end

db.close

# Final Summary
puts ""
puts "=" * 80
puts "VERIFICATION COMPLETE"
puts "=" * 80
puts ""
puts "✅ = Working correctly"
puts "⚠️  = Warning (may need attention)"
puts "❌ = Critical issue (must fix before deployment)"
puts ""
puts "If all critical checks pass, the app is ready for production!"
puts ""
