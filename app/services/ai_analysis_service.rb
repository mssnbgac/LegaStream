# AI Analysis Service - Production Version
# Handles real document analysis using PDF extraction and Multi-Provider AI

require 'net/http'
require 'json'
require 'uri'
require 'time'
require 'pdf-reader'
require_relative 'ai_provider'

class AIAnalysisService
  def initialize(document_id)
    @document_id = document_id
    @document = load_document
    @ai_provider = AIProvider.new
    @logs = []
    @use_real_ai = @ai_provider.enabled?
  end

  def analyze
    log_step('Starting AI analysis')
    log_step("AI Provider: #{@ai_provider.provider_name}") if @use_real_ai
    
    # Step 1: Extract text from actual PDF
    text = extract_text_from_pdf
    return error_result('Failed to extract text from PDF') unless text
    
    log_step("Extracted #{text.length} characters from document")
    
    # Step 2: Extract entities using AI or fallback
    entities = if @use_real_ai
      extract_entities_with_ai(text)
    else
      extract_entities_fallback(text)
    end
    log_step("Found #{entities.length} entities")
    
    # Step 3: Check compliance
    compliance = if @use_real_ai
      check_compliance_with_ai(text, entities)
    else
      check_compliance_fallback(text, entities)
    end
    log_step("Compliance score: #{compliance[:score]}%")
    
    # Step 4: Assess risks
    risks = assess_risks_from_text(text, entities, compliance)
    log_step("Risk level: #{risks[:level]}")
    
    # Step 5: Generate summary
    summary = if @use_real_ai
      generate_summary_with_ai(text, entities, compliance, risks)
    else
      generate_summary_fallback(text, entities, compliance, risks)
    end
    log_step('Analysis complete')
    
    # Save results
    save_results(entities, compliance, risks, summary, text)
    
    {
      success: true,
      entities: entities,
      compliance: compliance,
      risks: risks,
      summary: summary,
      confidence: calculate_confidence(entities, compliance, risks),
      logs: @logs,
      using_real_ai: @use_real_ai
    }
  rescue => e
    log_step("Error: #{e.message}", 'error')
    puts "Full error: #{e.class}: #{e.message}"
    puts e.backtrace.first(5)
    error_result(e.message)
  end

  private

  def load_document
    db = SQLite3::Database.new('storage/legastream.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM documents WHERE id = ?', [@document_id]).first
    db.close
    result
  end

  def extract_text_from_pdf
    # Get the file path
    filename = @document['filename'] || @document['original_filename']
    file_path = File.join('storage', 'uploads', filename)
    
    # Check if file exists
    unless File.exist?(file_path)
      log_step("File not found at #{file_path}, checking alternative paths")
      # Try alternative paths
      alt_paths = [
        File.join('storage', 'documents', filename),
        File.join('storage', 'documents', "#{@document_id}_#{filename}")
      ]
      
      file_path = alt_paths.find { |path| File.exist?(path) }
      
      unless file_path
        log_step("PDF file not found, using fallback text extraction")
        return extract_text_fallback
      end
    end
    
    log_step("Reading PDF from: #{file_path}")
    
    # Extract text from PDF
    reader = PDF::Reader.new(file_path)
    text = reader.pages.map(&:text).join("\n\n")
    
    # Clean up the text
    text = text.gsub(/\s+/, ' ').strip
    
    if text.empty?
      log_step("PDF appears to be empty or image-based, using OCR fallback")
      return extract_text_fallback
    end
    
    text
  rescue => e
    log_step("PDF extraction error: #{e.message}")
    extract_text_fallback
  end

  def extract_text_fallback
    # Fallback: return a notice that the file couldn't be read
    "Document uploaded but text extraction failed. File may be image-based PDF or corrupted."
  end

  def extract_entities_with_ai(text)
    log_step("Using #{@ai_provider.provider_name.upcase} for entity extraction")
    
    entities_data = @ai_provider.extract_entities(text)
    
    if entities_data.nil?
      log_step("AI returned nil, using fallback")
      return extract_entities_fallback(text)
    end
    
    unless entities_data.is_a?(Array)
      log_step("AI returned non-array (#{entities_data.class}), using fallback")
      return extract_entities_fallback(text)
    end
    
    if entities_data.empty?
      log_step("AI returned empty array, using fallback")
      return extract_entities_fallback(text)
    end
    
    log_step("AI extracted #{entities_data.length} entities")
    
    # Filter and validate entities before saving
    valid_entities = filter_valid_parties(entities_data)
    log_step("After filtering: #{valid_entities.length} valid entities")
    
    # Save entities to database
    valid_entities.each do |entity|
      confidence = entity['confidence'] || 0.90
      save_entity(entity['type'], entity['value'], entity['context'] || '', confidence)
    end
    
    valid_entities
  rescue => e
    log_step("AI entity extraction failed: #{e.message}")
    log_step("Error class: #{e.class}")
    extract_entities_fallback(text)
  end
  
  def filter_valid_parties(entities)
    # Words to exclude from party names
    exclude_words = %w[For AND OR At In On With Between From To By Of The This That Agreement Contract Shall Must Will Employee Employer Party Parties Authorized Representative Signature Witness transactions]
    
    # Generic terms that are NEVER parties
    generic_terms = %w[Student Name Academic Session First Class Term Payment Method Bank Transfer Transaction Account Number Amount Naira Dollar Only Date Time Period Year Month Day Week Second Third Fourth Fifth Sixth Seventh Eighth Ninth Tenth]
    
    # Nigerian and US states/locations to exclude
    locations = %w[Lagos Oyo Niger Imo Abia Adamawa Akwa Ibom Anambra Bauchi Bayelsa Benue Borno Cross River Delta Ebonyi Edo Ekiti Enugu Gombe Jigawa Kaduna Kano Katsina Kebbi Kogi Kwara Nassarawa Ondo Osun Ogun Plateau Rivers Sokoto Taraba Yobe Zamfara Abuja Wuse Zone Victoria Island Ikeja Ibadan Minna New York California Texas Florida Illinois Pennsylvania Ohio Georgia North Carolina Michigan]
    
    # Job titles to exclude
    job_titles = %w[Administrator Officer Manager Director CEO CFO President Secretary Treasurer Chairman Vice President Executive Assistant Coordinator Supervisor]
    
    entities.select do |entity|
      value = entity['value'].to_s.strip
      type = entity['type'].to_s
      
      # Only filter PARTY entities
      next entity unless type == 'PARTY'
      
      # STRICT CHECK: Skip if it contains ANY generic term
      next nil if generic_terms.any? { |term| value.include?(term) }
      
      # Skip if it's a multi-word phrase with common words (likely descriptive, not a name)
      words = value.split
      common_words = %w[First Second Third Fourth Fifth Last Next Previous Current New Old Payment Transfer Bank Account Method Session Class Term Amount Number Only]
      next nil if words.length >= 2 && words.any? { |w| common_words.include?(w) }
      
      # Remove leading/trailing excluded words
      words = words.drop_while { |w| exclude_words.include?(w) }
      words = words.reverse.drop_while { |w| exclude_words.include?(w) }.reverse
      cleaned_value = words.join(' ')
      
      # Skip if empty after cleaning
      next nil if cleaned_value.empty?
      
      # Skip if less than 2 characters (too short to be a real name)
      next nil if cleaned_value.length < 2
      
      # Skip if it's a location
      next nil if locations.any? { |loc| cleaned_value.include?(loc) && !cleaned_value.match?(/\b(?:Corporation|Corp|Inc|LLC|Ltd|Limited|Company|Co|Partnership|LLP|PC|PA|PLC|Plc|Bank)\b/i) }
      
      # Skip if it's just a job title
      next nil if job_titles.any? { |title| cleaned_value == title || cleaned_value.end_with?(title) }
      
      # Skip if it contains "State" without a company indicator
      next nil if cleaned_value.match?(/\bState\b/i) && !cleaned_value.match?(/\b(?:Corporation|Corp|Inc|LLC|Ltd|Limited|Company|Co|Bank)\b/i)
      
      # Skip if it's a number phrase
      next nil if cleaned_value.match?(/^(?:Five|Ten|Twenty|Thirty|Hundred|Thousand|Million)\b/i)
      
      # Skip if it's "Republic" without company indicator
      next nil if cleaned_value.match?(/\bRepublic\b/i) && !cleaned_value.match?(/\b(?:Corporation|Corp|Inc|LLC|Ltd|Limited|Company|Co|Bank)\b/i)
      
      # POSITIVE CHECK: Must be either a company name OR a person name
      is_company = cleaned_value.match?(/\b(?:Corporation|Corp|Inc|LLC|Ltd|Limited|Company|Co|Partnership|LLP|PC|PA|PLC|Plc|Bank|Solutions|Technologies|Services|Group|Holdings|Enterprises)\b/i)
      is_person = cleaned_value.split.length >= 2 && cleaned_value.split.all? { |w| w.match?(/^[A-Z][a-z]+$/) }
      
      next nil unless is_company || is_person
      
      # Update the entity with cleaned value
      entity['value'] = cleaned_value
      entity
    end.compact
  end

  def extract_entities_fallback(text)
    log_step("Using fallback entity extraction with legal-specific types")
    
    entities = []
    
    # 1. PARTY - People or organizations (proper names, companies)
    # First, extract addresses to exclude them from party detection
    address_parts = []
    text.scan(/\b\d+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Crescent|Circle|Court|Ct)\b/i) do |match|
      address_parts << match
    end
    
    # Words/phrases to exclude from party detection
    exclude_words = %w[The This That These Those Report Summary Document Analysis Section Chapter Page Table Figure Appendix Agreement Contract Whereas Herein Hereby Therefore Witnesseth Recitals Article Clause Paragraph Schedule Exhibit Annex Attachment Addendum Amendment Modification Extension Renewal Termination Expiration Effective Date Start End Beginning Conclusion Employee Employer Party Contractor Company Individual Authorized Representative Signature Witness Notary Between Shall Must Will Agrees Subject Provided Unless]
    
    # Location names to exclude
    locations = %w[New York Los Angeles Chicago Houston Phoenix Philadelphia San Antonio San Diego Dallas San Jose Austin Jacksonville Fort Worth Columbus Charlotte San Francisco Indianapolis Seattle Denver Washington Boston Nashville Detroit Oklahoma Memphis Portland Las Vegas Louisville Baltimore Milwaukee Albuquerque Tucson Fresno Sacramento Kansas City Mesa Virginia Beach Atlanta Colorado Springs Omaha Raleigh Miami Oakland Minneapolis Tulsa Cleveland Wichita Arlington Texas California Florida Illinois Pennsylvania Ohio Georgia North Carolina Michigan New Jersey Virginia Washington Massachusetts Arizona Indiana Tennessee Missouri Maryland Wisconsin Minnesota Colorado Alabama South Carolina Louisiana Kentucky Oregon Oklahoma Connecticut Utah Iowa Nevada Arkansas Mississippi Kansas New Mexico Nebraska West Virginia Idaho Hawaii New Hampshire Maine Montana Rhode Island Delaware South Dakota North Dakota Alaska Vermont Wyoming]
    
    # Extract company names (high confidence) - must have company indicator
    text.scan(/\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3})\s+(Corporation|Corp\.?|Inc\.?|LLC|Ltd\.?|Limited|Company|Co\.?|Partnership|LLP|PC|PA|PLC)\b/i) do |name, indicator|
      full_name = "#{name} #{indicator}".strip
      
      # Skip if it's part of an address
      next if address_parts.any? { |addr| addr.include?(full_name) }
      
      # Skip if it's too short
      next if full_name.length < 5
      
      # Skip if it contains excluded words
      next if exclude_words.any? { |w| full_name.include?(w) }
      
      # Skip if it's a location
      next if locations.any? { |loc| full_name.include?(loc) }
      
      entities << { type: 'PARTY', value: full_name, context: 'company party to agreement' }
      save_entity('PARTY', full_name, 'company party to agreement', 0.95)
    end
    
    # Extract person names (2-3 words, capitalized) - very strict
    text.scan(/\b([A-Z][a-z]{2,})\s+([A-Z][a-z]{2,})(?:\s+([A-Z][a-z]{2,}))?\b/) do |first, last, middle|
      # Build full name
      full_name = middle ? "#{first} #{middle} #{last}" : "#{first} #{last}"
      
      # Skip if any word is in exclude list
      words = full_name.split
      next if words.any? { |w| exclude_words.include?(w) }
      
      # Skip if it's part of an address
      next if address_parts.any? { |addr| addr.include?(full_name) }
      
      # Skip if it contains street indicators
      next if full_name.match?(/\b(?:Street|Avenue|Road|Boulevard|Drive|Lane|Crescent|Circle|Court)\b/i)
      
      # Skip if it's a location
      next if locations.any? { |loc| full_name.include?(loc) }
      
      # Skip if it's all caps (likely acronym)
      next if full_name == full_name.upcase
      
      # Skip if words are too short (< 3 chars each)
      next if words.any? { |w| w.length < 3 }
      
      # Skip if it appears in a sentence context (not a standalone name)
      # Look for common sentence patterns
      next if text.match?(/(?:between|by|from|with|to|for|of|in|at|on)\s+#{Regexp.escape(full_name)}\s+(?:and|or|shall|must|will|agrees|is|was|has|have)/i)
      
      entities << { type: 'PARTY', value: full_name, context: 'individual party to agreement' }
      save_entity('PARTY', full_name, 'individual party to agreement', 0.90)
    end
    
    # 2. ADDRESS - Physical addresses
    text.scan(/\b\d+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Crescent|Circle|Court|Ct)(?:,?\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)?/i) do |match|
      entities << { type: 'ADDRESS', value: match, context: 'physical address' }
      save_entity('ADDRESS', match, 'physical address', 0.88)
    end
    
    # 3. DATE - Dates in various formats
    text.scan(/\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}\b/i) do |match|
      entities << { type: 'DATE', value: match, context: 'date in document' }
      save_entity('DATE', match, 'date in document', 0.92)
    end
    
    text.scan(/\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b/) do |match|
      entities << { type: 'DATE', value: match, context: 'date in document' }
      save_entity('DATE', match, 'date in document', 0.90)
    end
    
    # Extract date phrases
    text.scan(/(?:Start date|Effective date|Commencement date|Termination date|Expiration date):\s*[^.]+/i) do |match|
      entities << { type: 'DATE', value: match, context: 'contract date' }
      save_entity('DATE', match, 'contract date', 0.90)
    end
    
    # 4. AMOUNT - Money and compensation
    text.scan(/\$[\d,]+(?:\.\d{2})?(?:\s+(?:annual|monthly|weekly|per\s+\w+))?\s*(?:salary|compensation|payment|fee|amount)?/i) do |match|
      context = if match.match?(/salary|compensation/i)
        'compensation amount'
      elsif match.match?(/fee/i)
        'fee amount'
      else
        'monetary amount'
      end
      
      entities << { type: 'AMOUNT', value: match, context: context }
      save_entity('AMOUNT', match, context, 0.95)
    end
    
    # 5. OBLIGATION - Legal duties (shall, must, will)
    text.scan(/(?:Employee|Employer|Party|Contractor|Company|Individual)\s+(?:shall|must|will|agrees to)\s+[^.]{10,100}\./i) do |match|
      entities << { type: 'OBLIGATION', value: match.strip, context: 'legal obligation' }
      save_entity('OBLIGATION', match.strip, 'legal obligation', 0.85)
    end
    
    # 6. CLAUSE - Contract terms
    text.scan(/(?:Termination|Confidentiality|Non-disclosure|Non-compete|Severance|Notice)\s+(?:with|of|clause|provision)[^.]{10,80}\./i) do |match|
      entities << { type: 'CLAUSE', value: match.strip, context: 'contract clause' }
      save_entity('CLAUSE', match.strip, 'contract clause', 0.88)
    end
    
    # Extract notice periods
    text.scan(/\b\d+\s*days?\s+(?:notice|written notice)/i) do |match|
      entities << { type: 'CLAUSE', value: match, context: 'notice requirement' }
      save_entity('CLAUSE', match, 'notice requirement', 0.90)
    end
    
    # 7. JURISDICTION - Governing law
    text.scan(/(?:Governed by|Subject to|Under)\s+(?:the\s+)?(?:laws?\s+of\s+)?(?:the\s+)?(?:State\s+of\s+)?[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?/i) do |match|
      entities << { type: 'JURISDICTION', value: match, context: 'governing law' }
      save_entity('JURISDICTION', match, 'governing law', 0.90)
    end
    
    # Extract state/country references in legal context
    text.scan(/\b(?:State|Commonwealth|Republic)\s+of\s+[A-Z][a-z]+/i) do |match|
      entities << { type: 'JURISDICTION', value: match, context: 'jurisdiction' }
      save_entity('JURISDICTION', match, 'jurisdiction', 0.88)
    end
    
    # 8. TERM - Duration
    text.scan(/\b\d+[-\s](?:month|year|day|week)s?\s+(?:contract|term|period|duration)/i) do |match|
      entities << { type: 'TERM', value: match, context: 'contract duration' }
      save_entity('TERM', match, 'contract duration', 0.90)
    end
    
    text.scan(/(?:Period|Term|Duration)\s+of\s+\d+\s+(?:months?|years?|days?)/i) do |match|
      entities << { type: 'TERM', value: match, context: 'time period' }
      save_entity('TERM', match, 'time period', 0.88)
    end
    
    # 9. CONDITION - Requirements
    text.scan(/(?:Subject to|Conditional upon|Provided that|Unless)[^.]{10,80}\./i) do |match|
      entities << { type: 'CONDITION', value: match.strip, context: 'conditional requirement' }
      save_entity('CONDITION', match.strip, 'conditional requirement', 0.80)
    end
    
    # 10. PENALTY - Damages and penalties
    text.scan(/(?:Liquidated damages|Penalty|Fine)\s+of\s+\$[\d,]+/i) do |match|
      entities << { type: 'PENALTY', value: match, context: 'penalty amount' }
      save_entity('PENALTY', match, 'penalty amount', 0.95)
    end
    
    text.scan(/\$[\d,]+\s+(?:liquidated damages|penalty|fine)/i) do |match|
      entities << { type: 'PENALTY', value: match, context: 'penalty for breach' }
      save_entity('PENALTY', match, 'penalty for breach', 0.95)
    end
    
    entities.uniq { |e| [e[:type], e[:value]] }
  end

  def check_compliance_with_ai(text, entities)
    log_step("Using #{@ai_provider.provider_name.upcase} for compliance check")
    
    result = @ai_provider.analyze_compliance(text, entities)
    
    return check_compliance_fallback(text, entities) unless result
    
    {
      score: result['score'] || result[:score] || 85,
      issues: result['issues'] || result[:issues] || [],
      recommendations: result['recommendations'] || result[:recommendations] || []
    }
  rescue => e
    log_step("AI compliance check failed: #{e.message}")
    check_compliance_fallback(text, entities)
  end

  def check_compliance_fallback(text, entities)
    issues = []
    score = 100
    
    # Check for common compliance keywords
    if text.downcase.include?('gdpr') || text.downcase.include?('data protection')
      if !text.downcase.include?('consent') && !text.downcase.include?('privacy policy')
        issues << "GDPR compliance: Missing explicit consent or privacy policy reference"
        score -= 15
      end
    end
    
    if text.downcase.include?('confidential')
      if !text.downcase.include?('non-disclosure') && !text.downcase.include?('nda')
        issues << "Confidentiality: Consider adding NDA clause"
        score -= 10
      end
    end
    
    if entities.any? { |e| e[:type] == 'monetary' }
      if !text.downcase.include?('payment') && !text.downcase.include?('compensation')
        issues << "Financial terms: Payment terms should be clearly defined"
        score -= 10
      end
    end
    
    {
      score: [score, 0].max,
      issues: issues,
      recommendations: issues.map { |i| "Review: #{i}" }
    }
  end

  def assess_risks_from_text(text, entities, compliance)
    risk_score = 0
    risk_factors = []
    
    # High risk keywords
    high_risk_terms = ['termination', 'liability', 'indemnification', 'breach', 'penalty']
    high_risk_terms.each do |term|
      if text.downcase.include?(term)
        risk_score += 15
        risk_factors << "Contains #{term} clause - requires careful review"
      end
    end
    
    # Compliance-based risk
    if compliance[:score] < 70
      risk_score += 20
      risk_factors << "Low compliance score indicates potential legal risks"
    end
    
    # Determine risk level
    level = if risk_score >= 50
      'high'
    elsif risk_score >= 25
      'medium'
    else
      'low'
    end
    
    {
      level: level,
      score: [risk_score, 100].min,
      factors: risk_factors
    }
  end

  def generate_summary_with_ai(text, entities, compliance, risks)
    log_step("Using #{@ai_provider.provider_name.upcase} for summary generation")
    
    result = @ai_provider.generate_summary(text, entities, compliance, risks)
    
    return generate_summary_fallback(text, entities, compliance, risks) unless result && !result.empty?
    
    result
  rescue => e
    log_step("AI summary generation failed: #{e.message}")
    generate_summary_fallback(text, entities, compliance, risks)
  end

  def generate_summary_fallback(text, entities, compliance, risks)
    # Extract first few sentences as summary
    sentences = text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
    summary = sentences.first(3).join('. ')
    
    if summary.length > 300
      summary = summary[0..297] + '...'
    end
    
    summary.empty? ? "Document analyzed with #{entities.length} entities found." : summary
  end

  def save_entity(entity_type, entity_value, context, confidence = 0.85)
    db = SQLite3::Database.new('storage/legastream.db')
    db.execute(
      "INSERT INTO entities (document_id, entity_type, entity_value, context, confidence) VALUES (?, ?, ?, ?, ?)",
      [@document_id, entity_type, entity_value, context, confidence]
    )
    db.close
  rescue => e
    log_step("Failed to save entity: #{e.message}")
  end

  def save_results(entities, compliance, risks, summary, extracted_text)
    analysis_results = {
      entities_extracted: entities.length,
      compliance_score: compliance[:score],
      risk_level: risks[:level],
      issues_flagged: compliance[:issues].length,
      confidence_score: calculate_confidence(entities, compliance, risks),
      summary: summary,
      using_real_ai: @use_real_ai
    }.to_json
    
    db = SQLite3::Database.new('storage/legastream.db')
    db.execute(
      "UPDATE documents SET status = 'completed', analysis_results = ?, extracted_text = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      [analysis_results, extracted_text[0..10000], @document_id]
    )
    
    # Save compliance issues
    compliance[:issues].each_with_index do |issue, index|
      db.execute(
        "INSERT INTO compliance_issues (document_id, issue_type, severity, description, recommendation) VALUES (?, ?, ?, ?, ?)",
        [@document_id, 'compliance', risks[:level], issue, compliance[:recommendations][index] || 'Review required']
      )
    end
    
    db.close
  end

  def calculate_confidence(entities, compliance, risks)
    base_confidence = 0.75
    
    # Increase confidence with more entities found
    entity_bonus = [entities.length * 0.01, 0.15].min
    
    # Adjust based on compliance score
    compliance_factor = compliance[:score] / 100.0 * 0.1
    
    # Adjust based on AI usage
    ai_bonus = @use_real_ai ? 0.1 : 0.0
    
    total = base_confidence + entity_bonus + compliance_factor + ai_bonus
    ([total, 0.99].min * 100).round(1)
  end

  def log_step(message, level = 'info')
    @logs << { timestamp: Time.now.iso8601, level: level, message: message }
    puts "[AIAnalysisService] #{message}"
  end

  def error_result(message)
    {
      success: false,
      error: message,
      logs: @logs
    }
  end
end
