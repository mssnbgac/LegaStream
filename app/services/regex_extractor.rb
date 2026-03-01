# Regex-based Entity Extractor
# Fallback for when AI API is unavailable or quota exceeded
# Provides basic entity extraction using pattern matching

class RegexExtractor
  LEGAL_ENTITY_TYPES = {
    'PARTY' => 'Legal party (person or organization)',
    'ADDRESS' => 'Physical or mailing address',
    'DATE' => 'Important date or deadline',
    'AMOUNT' => 'Monetary amount or financial term',
    'OBLIGATION' => 'Legal obligation or requirement',
    'CLAUSE' => 'Contract clause or provision',
    'JURISDICTION' => 'Legal jurisdiction or governing law',
    'TERM' => 'Contract term or duration',
    'CONDITION' => 'Condition precedent or subsequent',
    'PENALTY' => 'Penalty or liquidated damages'
  }

  def initialize(text)
    @text = text
    @entities = []
  end

  def extract_entities
    extract_amounts
    extract_dates
    extract_parties
    extract_addresses
    extract_terms
    extract_jurisdictions
    extract_obligations
    
    @entities
  end

  private

  def extract_amounts
    # Match currency amounts: $1,000, $50.00, Rs. 5000, etc.
    @text.scan(/(?:USD?|Rs\.?|INR|EUR|GBP)?\s*\$?\s*([\d,]+(?:\.\d{2})?)\s*(?:USD|Rs\.?|INR|EUR|GBP|dollars?|rupees?)?/i) do |match|
      amount = match[0]
      context = extract_context($~.offset(0)[0], 50)
      
      @entities << {
        entity_type: 'AMOUNT',
        entity_value: "$#{amount.gsub(',', '')}",
        context: context,
        confidence: 0.85
      }
    end
  end

  def extract_dates
    # Match various date formats
    patterns = [
      # January 1, 2026 or Jan 1, 2026
      /\b(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\.?\s+\d{1,2},?\s+\d{4}\b/i,
      # 01/01/2026 or 1-1-2026
      /\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b/,
      # 2026-01-01
      /\b\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}\b/
    ]
    
    patterns.each do |pattern|
      @text.scan(pattern) do |match|
        date = $~[0]
        context = extract_context($~.offset(0)[0], 40)
        
        @entities << {
          entity_type: 'DATE',
          entity_value: date,
          context: context,
          confidence: 0.90
        }
      end
    end
  end

  def extract_parties
    # Look for party patterns in legal documents
    patterns = [
      # "between [PARTY] and [PARTY]"
      /between\s+([A-Z][A-Za-z\s&.,]+?)(?:\s+and\s+|\s*,)/i,
      # "by and between [PARTY]"
      /by and between\s+([A-Z][A-Za-z\s&.,]+?)(?:\s+and\s+|\s*,)/i,
      # "[PARTY] (hereinafter"
      /([A-Z][A-Za-z\s&.,]+?)\s*\(hereinafter/i,
      # "Employer: [PARTY]" or "Employee: [PARTY]"
      /(?:Employer|Employee|Landlord|Tenant|Buyer|Seller|Client|Provider):\s*([A-Z][A-Za-z\s&.,]+?)(?:\n|$)/i
    ]
    
    patterns.each do |pattern|
      @text.scan(pattern) do |match|
        party = match[0].strip.gsub(/\s+/, ' ')
        next if party.length < 3 || party.length > 100
        
        context = determine_party_role(party)
        
        @entities << {
          entity_type: 'PARTY',
          entity_value: party,
          context: context,
          confidence: 0.80
        }
      end
    end
  end

  def extract_addresses
    # Match address patterns
    # Simple pattern: number + street + city/state
    @text.scan(/\d+\s+[A-Z][A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr)[.,]?\s*[A-Z][A-Za-z\s]+,?\s*[A-Z]{2}?\s*\d{5,6}?/i) do |match|
      address = $~[0].strip
      
      @entities << {
        entity_type: 'ADDRESS',
        entity_value: address,
        context: 'physical address',
        confidence: 0.75
      }
    end
  end

  def extract_terms
    # Match time periods and durations
    patterns = [
      # "24 months", "thirty (30) days"
      /(?:twenty-four|twelve|six|three|thirty|sixty|ninety|one hundred twenty)?\s*\(?\d+\)?\s*(?:days?|months?|years?|weeks?)/i,
      # "2 years", "6 months"
      /\b\d+\s*(?:days?|months?|years?|weeks?)\b/i
    ]
    
    patterns.each do |pattern|
      @text.scan(pattern) do |match|
        term = $~[0].strip
        context = extract_context($~.offset(0)[0], 50)
        
        @entities << {
          entity_type: 'TERM',
          entity_value: term,
          context: context,
          confidence: 0.85
        }
      end
    end
  end

  def extract_jurisdictions
    # Match jurisdiction patterns
    patterns = [
      # "State of [State]"
      /State of\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/,
      # "laws of [State/Country]"
      /laws of\s+(?:the\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/i,
      # "governed by [State] law"
      /governed by\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+law/i
    ]
    
    patterns.each do |pattern|
      @text.scan(pattern) do |match|
        jurisdiction = match[0].strip
        
        @entities << {
          entity_type: 'JURISDICTION',
          entity_value: jurisdiction,
          context: 'governing law',
          confidence: 0.85
        }
      end
    end
  end

  def extract_obligations
    # Match obligation patterns
    # Look for "shall" clauses
    @text.scan(/(?:Employee|Employer|Party|Tenant|Landlord|Buyer|Seller)\s+shall\s+([^.]+\.)/i) do |match|
      obligation = $~[0].strip
      next if obligation.length > 200
      
      @entities << {
        entity_type: 'OBLIGATION',
        entity_value: obligation,
        context: 'contractual obligation',
        confidence: 0.75
      }
    end
  end

  def extract_context(position, length)
    start_pos = [position - length, 0].max
    end_pos = [position + length, @text.length].min
    context = @text[start_pos...end_pos].strip
    
    # Clean up context
    context.gsub(/\s+/, ' ')[0..100]
  end

  def determine_party_role(party)
    text_lower = @text.downcase
    party_lower = party.downcase
    
    # Find the context around this party
    if text_lower.include?("employer") && text_lower.index(party_lower)
      return "Employer"
    elsif text_lower.include?("employee") && text_lower.index(party_lower)
      return "Employee"
    elsif text_lower.include?("landlord") && text_lower.index(party_lower)
      return "Landlord"
    elsif text_lower.include?("tenant") && text_lower.index(party_lower)
      return "Tenant"
    else
      return "Party"
    end
  end
end
