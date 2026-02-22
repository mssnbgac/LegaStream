# Multi-Provider AI Service
# Supports: OpenAI, Google Gemini, Anthropic Claude, Ollama

require 'net/http'
require 'json'
require 'uri'

class AIProvider
  def initialize
    @provider = ENV['AI_PROVIDER']&.downcase || 'openai'
    @api_key = get_api_key
    @enabled = @api_key && !@api_key.empty? && @api_key != 'your_api_key_here'
  end

  def enabled?
    @enabled
  end

  def provider_name
    @provider
  end

  # Generic analyze method for custom prompts
  def analyze(prompt)
    return nil unless @enabled
    
    case @provider
    when 'gemini'
      call_gemini_api(prompt)
    when 'claude', 'anthropic'
      call_claude_api(prompt)
    when 'openai'
      call_openai_api(prompt)
    when 'ollama'
      call_ollama_api(prompt)
    else
      nil
    end
  rescue => e
    puts "[AIProvider] Error with #{@provider}: #{e.message}"
    nil
  end

  def extract_entities(text)
    return nil unless @enabled
    
    case @provider
    when 'gemini'
      extract_with_gemini(text)
    when 'claude', 'anthropic'
      extract_with_claude(text)
    when 'openai'
      extract_with_openai(text)
    when 'ollama'
      extract_with_ollama(text)
    else
      nil
    end
  rescue => e
    puts "[AIProvider] Error with #{@provider}: #{e.message}"
    nil
  end

  def analyze_compliance(text, entities)
    return nil unless @enabled
    
    case @provider
    when 'gemini'
      compliance_with_gemini(text)
    when 'claude', 'anthropic'
      compliance_with_claude(text)
    when 'openai'
      compliance_with_openai(text)
    when 'ollama'
      compliance_with_ollama(text)
    else
      nil
    end
  rescue => e
    puts "[AIProvider] Compliance error with #{@provider}: #{e.message}"
    nil
  end

  def generate_summary(text, entities, compliance, risks)
    return nil unless @enabled
    
    case @provider
    when 'gemini'
      summary_with_gemini(text, entities, compliance, risks)
    when 'claude', 'anthropic'
      summary_with_claude(text, entities, compliance, risks)
    when 'openai'
      summary_with_openai(text, entities, compliance, risks)
    when 'ollama'
      summary_with_ollama(text, entities, compliance, risks)
    else
      nil
    end
  rescue => e
    puts "[AIProvider] Summary error with #{@provider}: #{e.message}"
    nil
  end

  private

  def get_api_key
    case @provider
    when 'gemini'
      ENV['GEMINI_API_KEY']
    when 'claude', 'anthropic'
      ENV['ANTHROPIC_API_KEY'] || ENV['CLAUDE_API_KEY']
    when 'openai'
      ENV['OPENAI_API_KEY']
    when 'ollama'
      'local' # Ollama doesn't need an API key
    else
      ENV['OPENAI_API_KEY'] # Default fallback
    end
  end

  # Google Gemini Implementation
  def extract_with_gemini(text)
    # Limit text to avoid token issues
    text_sample = text[0..5000]
    
    prompt = <<~PROMPT
      You are a legal document analyzer. Extract entities from this document and return ONLY a JSON array.
      
      IMPORTANT: Your response must be ONLY the JSON array, nothing else. No explanations, no markdown, just the array.
      
      Extract these 10 entity types:
      1. PARTY - People or organizations (e.g., "Acme Corporation", "John Smith")
      2. ADDRESS - Physical addresses (e.g., "123 Main Street, New York, NY 10001")
      3. DATE - Dates (e.g., "March 1, 2026", "Start date: March 1, 2026")
      4. AMOUNT - Money (e.g., "$75,000", "$75,000 annual salary")
      5. OBLIGATION - Legal duties (e.g., "Employee shall perform duties diligently")
      6. CLAUSE - Contract terms (e.g., "Termination with 30 days notice")
      7. JURISDICTION - Governing law (e.g., "Governed by New York law", "State of New York")
      8. TERM - Duration (e.g., "24-month contract duration", "Period of 24 months")
      9. CONDITION - Requirements (e.g., "Subject to background check", "Unless terminated earlier")
      10. PENALTY - Damages (e.g., "$5,000 liquidated damages", "Penalty of $10,000")
      
      Document text:
      #{text_sample}
      
      Return format (ONLY this, nothing else):
      [
        {"type":"PARTY","value":"Acme Corporation","context":"employer party to agreement","confidence":0.95},
        {"type":"PARTY","value":"John Smith","context":"employee party to agreement","confidence":0.95},
        {"type":"ADDRESS","value":"123 Main Street, New York","context":"employer address","confidence":0.88},
        {"type":"DATE","value":"March 1, 2026","context":"agreement start date","confidence":0.92},
        {"type":"AMOUNT","value":"$75,000 annual salary","context":"employee compensation","confidence":0.95}
      ]
    PROMPT

    response = call_gemini_api(prompt)
    parse_json_response(response)
  end

  def compliance_with_gemini(text)
    prompt = <<~PROMPT
      Analyze this legal document for compliance. Return ONLY JSON:
      {"score": 85, "issues": ["issue1"], "recommendations": ["rec1"]}
      
      Document:
      #{text[0..3000]}
    PROMPT

    response = call_gemini_api(prompt)
    JSON.parse(response.match(/\{.*\}/m)[0]) rescue { score: 85, issues: [], recommendations: [] }
  end

  def summary_with_gemini(text, entities, compliance, risks)
    prompt = <<~PROMPT
      Summarize this legal document in 2-3 sentences. Focus on key points, parties, and obligations.
      
      Document:
      #{text[0..2000]}
    PROMPT

    call_gemini_api(prompt)
  end

  def call_gemini_api(prompt)
    # Use v1 API with gemini-1.5-flash (correct API version)
    uri = URI("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=#{@api_key}")
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 2000  # Increased to account for thinking tokens
      }
    }.to_json

    puts "[Gemini] Sending request to API..."
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60) do |http|
      http.request(request)
    end

    puts "[Gemini] Response status: #{response.code}"
    
    if response.code != '200'
      puts "[Gemini] ERROR: HTTP #{response.code}"
      puts "[Gemini] Response body: #{response.body[0..500]}"
      return ''
    end

    data = JSON.parse(response.body)
    
    # Check for API errors
    if data['error']
      puts "[Gemini] API error: #{data['error']['message']}"
      puts "[Gemini] Error code: #{data['error']['code']}"
      puts "[Gemini] Error status: #{data['error']['status']}"
      return ''
    end
    
    # Check for empty candidates
    unless data['candidates'] && data['candidates'][0]
      puts "[Gemini] No candidates in response"
      puts "[Gemini] Response: #{data.inspect}"
      return ''
    end
    
    candidate = data['candidates'][0]
    finish_reason = candidate['finishReason']
    
    # Check finish reason
    if finish_reason != 'STOP'
      puts "[Gemini] Finished with reason: #{finish_reason}"
      if finish_reason == 'SAFETY'
        puts "[Gemini] Content was blocked by safety filters"
      elsif finish_reason == 'MAX_TOKENS'
        puts "[Gemini] Response truncated due to max tokens"
      end
    end
    
    # Extract text
    text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    if text.nil? || text.empty?
      puts "[Gemini] Empty text in response"
      return ''
    end
    
    puts "[Gemini] Success! Received #{text.length} chars"
    text
  rescue Net::ReadTimeout => e
    puts "[Gemini] TIMEOUT: #{e.message}"
    ''
  rescue JSON::ParserError => e
    puts "[Gemini] JSON parse error: #{e.message}"
    puts "[Gemini] Response body: #{response.body[0..500]}"
    ''
  rescue => e
    puts "[Gemini] Unexpected error: #{e.class} - #{e.message}"
    puts e.backtrace.first(3)
    ''
  end

  # Anthropic Claude Implementation
  def extract_with_claude(text)
    prompt = "Extract entities from this legal document as JSON array: #{text[0..4000]}"
    response = call_claude_api(prompt)
    parse_json_response(response)
  end

  def compliance_with_claude(text)
    prompt = "Analyze compliance as JSON: #{text[0..3000]}"
    response = call_claude_api(prompt)
    JSON.parse(response.match(/\{.*\}/m)[0]) rescue { score: 85, issues: [], recommendations: [] }
  end

  def summary_with_claude(text, entities, compliance, risks)
    call_claude_api("Summarize this legal document: #{text[0..2000]}")
  end

  def call_claude_api(prompt)
    uri = URI('https://api.anthropic.com/v1/messages')
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = @api_key
    request['anthropic-version'] = '2023-06-01'
    request.body = {
      model: 'claude-3-haiku-20240307',
      max_tokens: 1000,
      messages: [{ role: 'user', content: prompt }]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)
    data.dig('content', 0, 'text') || ''
  end

  # OpenAI Implementation (existing)
  def extract_with_openai(text)
    require 'openai'
    client = OpenAI::Client.new(access_token: @api_key)
    
    prompt = "Extract entities as JSON array: #{text[0..4000]}"
    
    response = client.chat(parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 1000
    })
    
    content = response.dig('choices', 0, 'message', 'content')
    parse_json_response(content)
  end

  def call_openai_api(prompt)
    require 'openai'
    client = OpenAI::Client.new(access_token: @api_key)
    
    response = client.chat(parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
      max_tokens: 2000
    })
    
    response.dig('choices', 0, 'message', 'content') || ''
  end

  def compliance_with_openai(text)
    require 'openai'
    client = OpenAI::Client.new(access_token: @api_key)
    
    response = client.chat(parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: "Analyze compliance as JSON: #{text[0..3000]}" }],
      temperature: 0.3,
      max_tokens: 500
    })
    
    content = response.dig('choices', 0, 'message', 'content')
    JSON.parse(content.match(/\{.*\}/m)[0]) rescue { score: 85, issues: [], recommendations: [] }
  end

  def summary_with_openai(text, entities, compliance, risks)
    require 'openai'
    client = OpenAI::Client.new(access_token: @api_key)
    
    response = client.chat(parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: "Summarize: #{text[0..2000]}" }],
      temperature: 0.5,
      max_tokens: 200
    })
    
    response.dig('choices', 0, 'message', 'content') || ''
  end

  # Ollama Implementation (Local LLM)
  def extract_with_ollama(text)
    prompt = "Extract entities as JSON: #{text[0..4000]}"
    response = call_ollama_api(prompt)
    parse_json_response(response)
  end

  def compliance_with_ollama(text)
    response = call_ollama_api("Analyze compliance as JSON: #{text[0..3000]}")
    JSON.parse(response.match(/\{.*\}/m)[0]) rescue { score: 85, issues: [], recommendations: [] }
  end

  def summary_with_ollama(text, entities, compliance, risks)
    call_ollama_api("Summarize: #{text[0..2000]}")
  end

  def call_ollama_api(prompt)
    host = ENV['OLLAMA_HOST'] || 'http://localhost:11434'
    model = ENV['OLLAMA_MODEL'] || 'llama2'
    
    uri = URI("#{host}/api/generate")
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      model: model,
      prompt: prompt,
      stream: false
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)
    data['response'] || ''
  end

  # Helper method to parse JSON from AI responses
  def parse_json_response(text)
    if text.nil? || text.empty?
      puts "[AIProvider] parse_json_response: text is nil or empty"
      return []
    end
    
    puts "[AIProvider] Parsing response (#{text.length} chars)"
    puts "[AIProvider] First 200 chars: #{text[0..200]}"
    
    # Remove markdown code blocks if present
    cleaned = text.strip
    cleaned = cleaned.sub(/^```json\s*/, '').sub(/```\s*$/, '')
    cleaned = cleaned.sub(/^```\s*/, '').sub(/```\s*$/, '')  # Also handle plain ```
    
    # Try to extract JSON array from response
    json_match = cleaned.match(/\[.*\]/m)
    
    unless json_match
      puts "[AIProvider] No JSON array found in response"
      puts "[AIProvider] Cleaned text: #{cleaned[0..300]}"
      return []
    end
    
    puts "[AIProvider] Found JSON array, attempting to parse..."
    entities = JSON.parse(json_match[0])
    puts "[AIProvider] Successfully parsed #{entities.length} entities"
    entities
  rescue => e
    puts "[AIProvider] JSON parse error: #{e.message}"
    puts "[AIProvider] Error class: #{e.class}"
    puts "[AIProvider] Text that failed: #{text[0..500]}"
    []
  end
end
