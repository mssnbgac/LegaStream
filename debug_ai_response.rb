require 'net/http'
require 'json'
require 'uri'

# Load API key
api_key = nil
File.readlines('.env').each do |line|
  if line.start_with?('GEMINI_API_KEY=')
    api_key = line.split('=', 2)[1].strip
    break
  end
end

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

prompt = <<~PROMPT
  You are a legal document analyzer. Extract ONLY the actual contracting parties from this document.

  STRICT RULES FOR PARTY EXTRACTION:
  1. ONLY extract names of people or organizations who are SIGNING the agreement
  2. Look for parties in:
     - "This Agreement is between [PARTY A] and [PARTY B]"
     - Signature blocks at the end
     - "The parties to this agreement are..."
  3. Extract ONLY clean names:
     - Companies: "Acme Corporation", "Tech Solutions LLC", "BrightPath Limited"
     - People: "John Smith", "Mary Johnson", "Abdul Mai"
  4. DO NOT extract:
     - Generic terms: "Student Name", "Academic Session", "First Term"
     - Financial terms: "Payment Method", "Account Number", "Transfer"
     - Descriptive phrases: "First Class Term", "Payment Bank Method"
     - Currencies: "Naira", "Dollar"
     - Sentence fragments or partial phrases
     - Anything that is not a proper name

  For OTHER entity types, extract normally:
  - ADDRESS: Physical addresses only
  - DATE: Dates in any format
  - AMOUNT: Money amounts with currency symbols
  - OBLIGATION: Legal duties (shall, must, will)
  - CLAUSE: Contract terms and conditions
  - JURISDICTION: Governing law references
  - TERM: Duration/time periods
  - CONDITION: Requirements and conditions
  - PENALTY: Damages and penalties

  Document:
  #{text[0..4000]}

  Return ONLY a valid JSON array. Each entity must have: type, value, context, confidence.
  Example: [{"type":"PARTY","value":"Acme Corporation","context":"employer","confidence":0.95}]

  If no clear parties are found, return an empty array for PARTY type.
PROMPT

uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")

request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = {
  contents: [{
    parts: [{ text: prompt }]
  }],
  generationConfig: {
    temperature: 0.1,
    maxOutputTokens: 2048,
    topP: 0.8,
    topK: 10
  }
}.to_json

puts "Sending request to Gemini..."
puts ""

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60) do |http|
  http.request(request)
end

if response.code == '200'
  data = JSON.parse(response.body)
  text_response = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
  
  puts "Raw AI Response:"
  puts "=" * 80
  puts text_response
  puts "=" * 80
  puts ""
  
  # Try to parse JSON
  cleaned = text_response.strip.gsub(/```json\s*/i, '').gsub(/```\s*$/, '')
  json_match = cleaned.match(/\[.*\]/m)
  
  if json_match
    entities = JSON.parse(json_match[0])
    puts "Parsed #{entities.length} entities:"
    puts ""
    
    by_type = entities.group_by { |e| e['type'] }
    by_type.each do |type, ents|
      puts "#{type} (#{ents.length}):"
      ents.each do |e|
        puts "  - #{e['value']}"
        puts "    Context: #{e['context']}"
        puts "    Confidence: #{(e['confidence'] * 100).to_i}%"
      end
      puts ""
    end
  else
    puts "❌ Could not parse JSON from response"
  end
  
else
  puts "❌ API Error: #{response.code}"
  puts response.body
end
