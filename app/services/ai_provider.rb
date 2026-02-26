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
      text_sample = text[0..4000]

      prompt = <<~PROMPT
        You are a legal document analyzer. Extract entities with MAXIMUM PRECISION and CLEANLINESS.

        CRITICAL RULES FOR ALL ENTITIES:
        1. Extract ONLY complete, standalone values - NO sentence fragments
        2. Extract ONLY the core entity - NO surrounding text
        3. Each entity must be independently meaningful
        4. NO partial phrases, NO incomplete sentences

        ENTITY TYPES AND EXTRACTION RULES:

        **PARTY** (People or organizations signing the agreement):
        - Extract ONLY actual names: "Acme Corporation", "John Smith"
        - Look in: "between [NAME] and [NAME]", signature blocks
        - DO NOT extract: "is made between", "and in accordance with", sentence fragments
        - Must be a complete proper name

        **ADDRESS** (Physical locations):
        - Extract complete addresses: "123 Main Street, New York"
        - DO NOT extract: partial addresses, city names alone

        **DATE** (Important dates):
        - Extract specific dates: "March 1, 2026", "January 15, 2025"
        - DO NOT extract: "on" or "as of" prefixes

        **AMOUNT** (Monetary values):
        - Extract clean amounts: "$75,000", "$5,000"
        - Include context: "annual salary", "penalty", "liquidated damages"
        - DO NOT extract: surrounding text like "subject to" or "payable in"

        **OBLIGATION** (Legal duties):
        - Extract COMPLETE obligation sentences
        - Must start with subject: "Employee shall...", "Employer shall..."
        - Must be a full, meaningful obligation
        - DO NOT extract: fragments like "subject to lawful deductions"

        **CLAUSE** (Contract terms):
        - Extract COMPLETE clause sentences
        - Must be independently understandable
        - Example: "Either party may terminate this Agreement by providing thirty (30) days written notice."

        **JURISDICTION** (Governing law):
        - Extract clean jurisdiction: "State of New York", "laws of California"
        - DO NOT extract: "subject to", "governed by" prefixes

        **TERM** (Duration/time periods):
        - Extract specific durations: "twenty-four (24) months", "thirty (30) days"
        - Include context: "contract duration", "notice period"

        **CONDITION** (Requirements):
        - Extract complete conditions: "successful completion of a background check"
        - Must be a complete requirement phrase

        **PENALTY** (Damages/fines):
        - Extract COMPLETE penalty clauses
        - Must include what triggers it and the consequence

        Document:
        #{text_sample}

        Return ONLY a valid JSON array. Each entity MUST have: type, value, context, confidence.
        
        QUALITY CHECKLIST FOR EACH ENTITY:
        ✓ Is the value complete and standalone?
        ✓ Does it make sense without surrounding text?
        ✓ Is it free of sentence fragments?
        ✓ Is the context descriptive and clear?

        Example of PERFECT extraction:
        [
          {"type":"PARTY","value":"Acme Corporation","context":"Employer","confidence":0.95},
          {"type":"PARTY","value":"John Smith","context":"Employee","confidence":0.95},
          {"type":"AMOUNT","value":"$75,000","context":"annual salary","confidence":0.95}
        ]

        Example of BAD extraction (DO NOT DO THIS):
        [
          {"type":"PARTY","value":"is made between Acme Corporation","context":"party","confidence":0.95},
          {"type":"AMOUNT","value":"$75,000, subject to lawful deductions","context":"amount","confidence":0.95}
        ]
      PROMPT

      response = call_gemini_api(prompt)

      if response.nil? || response.empty?
        puts "[AIProvider] Gemini returned empty response"
        return []
      end

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
    # Extract key information for context
    parties = entities.select { |e| (e['type'] || e[:type]) == 'PARTY' }.map { |e| e['value'] || e[:value] }.first(3)
    dates = entities.select { |e| (e['type'] || e[:type]) == 'DATE' }.map { |e| e['value'] || e[:value] }.first(2)
    amounts = entities.select { |e| (e['type'] || e[:type]) == 'AMOUNT' }.map { |e| e['value'] || e[:value] }.first(2)
    
    prompt = <<~PROMPT
      Create a concise executive summary of this legal document in EXACTLY 3-4 sentences (maximum 250 words).

      Structure your summary as follows:
      1. First sentence: Document type and date
      2. Second sentence: Main parties involved
      3. Third sentence: Key terms, amounts, or obligations
      4. Fourth sentence (optional): Important conditions or deadlines

      Key entities found:
      - Parties: #{parties.join(', ')}
      - Dates: #{dates.join(', ')}
      - Amounts: #{amounts.join(', ')}

      Document excerpt:
      #{text[0..2000]}

      Write a clear, professional summary that a business executive can read in 30 seconds.
      Focus on WHO, WHAT, WHEN, and HOW MUCH.
      Do NOT include legal jargon or unnecessary details.
    PROMPT

    summary = call_gemini_api(prompt)
    
    # Ensure summary is not too long (max 250 words)
    if summary && summary.split.length > 250
      words = summary.split[0..249]
      summary = words.join(' ') + '...'
    end
    
    summary
  end

  def call_gemini_api(prompt)
    # Use v1beta API with gemini-2.5-flash (latest fast model)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{@api_key}")
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.1,  # Lower temperature for more consistent JSON
        maxOutputTokens: 4096,  # Increased to handle all 10 entity types
        topP: 0.8,
        topK: 10
      }
    }.to_json

    puts "[Gemini] Sending request to API..."
    puts "[Gemini] Prompt length: #{prompt.length} chars"
    
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
      puts "[Gemini] Response: #{data.inspect[0..500]}"
      return ''
    end
    
    candidate = data['candidates'][0]
    finish_reason = candidate['finishReason']
    
    # Check finish reason
    if finish_reason && finish_reason != 'STOP'
      puts "[Gemini] Finished with reason: #{finish_reason}"
      if finish_reason == 'SAFETY'
        puts "[Gemini] Content was blocked by safety filters"
        puts "[Gemini] Safety ratings: #{candidate['safetyRatings'].inspect}" if candidate['safetyRatings']
      elsif finish_reason == 'MAX_TOKENS'
        puts "[Gemini] Response truncated due to max tokens"
      elsif finish_reason == 'RECITATION'
        puts "[Gemini] Content blocked due to recitation"
      end
    end
    
    # Extract text
    text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    if text.nil? || text.empty?
      puts "[Gemini] Empty text in response"
      puts "[Gemini] Candidate structure: #{candidate.inspect[0..500]}"
      return ''
    end
    
    puts "[Gemini] Success! Received #{text.length} chars"
    puts "[Gemini] Response preview: #{text[0..200]}"
    text
  rescue Net::ReadTimeout => e
    puts "[Gemini] TIMEOUT: #{e.message}"
    ''
  rescue JSON::ParserError => e
    puts "[Gemini] JSON parse error: #{e.message}"
    puts "[Gemini] Response body: #{response.body[0..500]}" if response
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
    puts "[AIProvider] First 300 chars: #{text[0..300]}"
    
    # Remove markdown code blocks if present
    cleaned = text.strip
    cleaned = cleaned.gsub(/```json\s*/i, '').gsub(/```\s*$/, '')
    cleaned = cleaned.gsub(/```\s*/i, '').gsub(/```\s*$/, '')
    
    # Remove any leading text before the JSON array
    if cleaned =~ /\[/
      start_pos = cleaned.index('[')
      cleaned = cleaned[start_pos..-1]
    end
    
    # Remove any trailing text after the JSON array
    if cleaned =~ /\]/
      end_pos = cleaned.rindex(']')
      cleaned = cleaned[0..end_pos]
    end
    
    # Try to extract JSON array from response
    json_match = cleaned.match(/\[.*\]/m)
    
    unless json_match
      puts "[AIProvider] No JSON array found in response"
      puts "[AIProvider] Cleaned text: #{cleaned[0..500]}"
      
      # Try to find if there's any JSON-like structure
      if cleaned.include?('{') && cleaned.include?('}')
        puts "[AIProvider] Found JSON objects but not in array format"
        # Try to wrap in array
        cleaned = "[#{cleaned}]" if !cleaned.start_with?('[')
        json_match = cleaned.match(/\[.*\]/m)
      end
      
      return [] unless json_match
    end
    
    puts "[AIProvider] Found JSON array, attempting to parse..."
    json_str = json_match[0]
    
    # Clean up common JSON issues
    json_str = json_str.gsub(/,\s*\]/, ']')  # Remove trailing commas
    json_str = json_str.gsub(/,\s*\}/, '}')  # Remove trailing commas in objects
    
    entities = JSON.parse(json_str)
    puts "[AIProvider] Successfully parsed #{entities.length} entities"
    
    # Validate entity structure
    valid_entities = entities.select do |e|
      e.is_a?(Hash) && e['type'] && e['value']
    end
    
    if valid_entities.length < entities.length
      puts "[AIProvider] Filtered out #{entities.length - valid_entities.length} invalid entities"
    end
    
    valid_entities
  rescue JSON::ParserError => e
    puts "[AIProvider] JSON parse error: #{e.message}"
    puts "[AIProvider] Error class: #{e.class}"
    puts "[AIProvider] JSON string that failed: #{json_str[0..500]}" if json_str
    []
  rescue => e
    puts "[AIProvider] Unexpected error: #{e.class} - #{e.message}"
    puts "[AIProvider] Text that failed: #{text[0..500]}"
    []
  end
end
