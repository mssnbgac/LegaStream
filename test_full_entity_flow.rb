require 'sqlite3'
require 'json'
require_relative 'app/services/ai_provider'
require_relative 'app/services/ai_analysis_service'

puts "=" * 80
puts "TESTING FULL ENTITY EXTRACTION FLOW"
puts "=" * 80
puts ""

# Sample text from the employment contract
text = <<~TEXT
  EMPLOYMENT AGREEMENT

  This Employment Agreement ("Agreement") is made and entered into as of March 1, 2026,
  by and between Acme Corporation ("Employer") and John Smith ("Employee").

  1. POSITION AND DUTIES
  Employee shall serve as Software Engineer and shall perform duties diligently and
  professionally in the best interests of the Employer.

  2. COMPENSATION
  Employer shall pay Employee an annual salary of $75,000, payable in accordance with
  Employer's standard payroll practices.

  3. TERM
  This Agreement shall commence on March 1, 2026 and shall continue for a period of
  24 months unless earlier terminated.

  4. TERMINATION
  Either party may terminate this Agreement with 30 days' written notice.

  5. LIQUIDATED DAMAGES
  In the event of material breach, the breaching party shall pay liquidated damages
  of $5,000 to the non-breaching party.

  6. CONDITIONS
  This Agreement is subject to successful completion of a background check.

  7. LOCATION
  Employee shall primarily perform services at 123 Main Street, New York.

  8. GOVERNING LAW
  This Agreement shall be governed by the laws of the State of New York.
TEXT

puts "Testing AI Provider directly..."
puts ""

provider = AIProvider.new

if provider.enabled?
  puts "✅ AI Provider enabled: #{provider.provider_name}"
  puts ""
  
  puts "Extracting entities..."
  entities = provider.extract_entities(text)
  
  puts "Entities returned from AI: #{entities.length}"
  puts ""
  
  if entities.any?
    # Group by type
    by_type = entities.group_by { |e| e['type'] || e[:type] }
    
    by_type.each do |type, ents|
      puts "#{type} (#{ents.length}):"
      ents.each do |e|
        value = e['value'] || e[:value]
        context = e['context'] || e[:context]
        confidence = e['confidence'] || e[:confidence]
        puts "  - #{value}"
        puts "    Context: #{context}"
        puts "    Confidence: #{(confidence * 100).to_i}%"
      end
      puts ""
    end
    
    # Check for key entities
    puts "=" * 80
    puts "KEY ENTITIES CHECK:"
    puts "=" * 80
    
    checks = {
      "Acme Corporation" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('Acme') },
      "John Smith" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('John Smith') },
      "$75,000" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('75,000') || (e['value'] || e[:value]).to_s.include?('75000') },
      "$5,000 penalty" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('5,000') || (e['value'] || e[:value]).to_s.include?('5000') },
      "24-month term" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('24') },
      "30 days notice" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('30') },
      "background check" => entities.any? { |e| (e['value'] || e[:value]).to_s.downcase.include?('background') },
      "New York law" => entities.any? { |e| (e['value'] || e[:value]).to_s.include?('New York') }
    }
    
    checks.each do |entity, found|
      status = found ? "✅" : "❌"
      puts "  #{status} #{entity}"
    end
    
  else
    puts "❌ No entities returned from AI"
  end
  
else
  puts "❌ AI Provider not enabled"
  puts "Check .env file for GEMINI_API_KEY"
end
