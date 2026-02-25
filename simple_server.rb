#!/usr/bin/env ruby
require 'webrick'
require 'json'
require 'fileutils'
require 'base64'
require 'digest'

# Load environment variables from .env file
begin
  require 'dotenv/load'
rescue LoadError
  # dotenv not available, will use system environment variables
  puts "Warning: dotenv gem not found, using system environment variables"
end

# Enhanced LegaStream Backend Server with Document Processing
class LegaStreamServer
  def initialize(port = 6000)
    @port = port
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      DocumentRoot: '.',
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
    
    # Create storage directories
    FileUtils.mkdir_p('storage/documents')
    FileUtils.mkdir_p('storage/processed')
    
    # In-memory storage for demo (in production, use database)
    @documents = []
    @processing_jobs = {}
    
    setup_routes
    setup_cors
  end

  def setup_cors
    @server.mount_proc '/' do |req, res|
      # Set CORS headers for all requests
      res['Access-Control-Allow-Origin'] = '*'
      res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      res['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Tenant-ID, Accept'
      res['Access-Control-Max-Age'] = '86400'
      
      # Handle preflight OPTIONS requests
      if req.request_method == 'OPTIONS'
        res.status = 200
        res.body = ''
        return
      end
      
      handle_request(req, res)
    end
  end

  def setup_routes
    # Health check
    @server.mount_proc '/up' do |req, res|
      res['Content-Type'] = 'application/json'
      res.body = {
        status: 'ok',
        timestamp: Time.now.iso8601,
        version: '2.1.0',
        services: {
          backend: 'running',
          document_processor: 'active',
          ai_engine: 'ready',
          storage: 'available'
        }
      }.to_json
    end
  end

  def handle_request(req, res)
    path = req.path
    method = req.request_method
    
    puts "[#{Time.now}] #{method} #{path}"
    puts "DEBUG: Checking routes for path: #{path}"
    
    case path
    when '/up'
      puts "DEBUG: Matched /up route"
      # Already handled above
    when '/api/v1/auth/login'
      puts "DEBUG: Matched login route"
      handle_login(req, res)
    when '/api/v1/auth/register'
      puts "DEBUG: Matched register route"
      handle_register(req, res)
    when '/api/v1/auth/forgot_password'
      puts "DEBUG: Matched forgot_password route"
      handle_forgot_password(req, res)
    when '/api/v1/documents'
      puts "DEBUG: Matched documents route"
      handle_documents(req, res, method)
    when %r{^/api/v1/documents/(\d+)$}
      puts "DEBUG: Matched document detail route"
      handle_document_detail(req, res, method, $1)
    when %r{^/api/v1/documents/(\d+)/analyze$}
      puts "DEBUG: Matched document analyze route"
      handle_document_analyze(req, res, $1)
    when %r{^/api/v1/documents/(\d+)/status$}
      puts "DEBUG: Matched document status route"
      handle_document_status(req, res, $1)
    when %r{^/api/v1/documents/(\d+)/entities$}
      puts "DEBUG: Matched document entities route"
      handle_document_entities(req, res, $1)
    when '/api/v1/stats'
      puts "DEBUG: Matched stats route"
      handle_stats(req, res)
    else
      puts "DEBUG: No route matched, returning 404"
      res.status = 404
      res['Content-Type'] = 'application/json'
      res.body = { error: 'Not Found' }.to_json
    end
  end

  def handle_login(req, res)
    res['Content-Type'] = 'application/json'
    
    # Mock successful login
    res.body = {
      token: 'mock_jwt_token_12345',
      user: {
        id: 1,
        email: 'admin@legastream.com',
        name: 'Admin User',
        tenant_id: 1
      }
    }.to_json
  end

  def handle_register(req, res)
    res['Content-Type'] = 'application/json'
    
    begin
      data = JSON.parse(req.body)
      user_data = data['user'] || {}
      
      # Mock successful registration
      res.status = 201
      res.body = {
        message: 'Registration successful! Please check your email to confirm your account.',
        user: {
          id: rand(100..999),
          email: user_data['email'],
          first_name: user_data['first_name'],
          last_name: user_data['last_name'],
          full_name: "#{user_data['first_name']} #{user_data['last_name']}",
          role: 'user',
          email_confirmed: false,
          tenant: {
            id: 1,
            name: 'Demo Tenant',
            subscription_tier: 'basic'
          }
        }
      }.to_json
    rescue JSON::ParserError
      res.status = 400
      res.body = { errors: ['Invalid JSON data'] }.to_json
    rescue => e
      res.status = 500
      res.body = { errors: ['Registration failed. Please try again.'] }.to_json
    end
  end

  def handle_forgot_password(req, res)
    res['Content-Type'] = 'application/json'
    
    begin
      data = JSON.parse(req.body)
      email = data['email']
      
      # Mock successful password reset request
      res.body = {
        message: 'If an account with that email exists, password reset instructions have been sent'
      }.to_json
    rescue => e
      res.status = 500
      res.body = { error: 'Failed to send reset instructions.' }.to_json
    end
  end

  def handle_documents(req, res, method)
    res['Content-Type'] = 'application/json'
    
    case method
    when 'GET'
      # Return documents with enhanced data
      res.body = {
        documents: @documents.map { |doc| format_document(doc) },
        total: @documents.length,
        processing: @documents.count { |d| d[:status] == 'processing' },
        completed: @documents.count { |d| d[:status] == 'completed' }
      }.to_json
      
    when 'POST'
      # Handle document upload
      begin
        content_type = req['Content-Type']
        
        if content_type&.include?('multipart/form-data')
          # Handle multipart file upload
          handle_file_upload(req, res)
        else
          # Handle JSON upload (base64 encoded)
          handle_json_upload(req, res)
        end
      rescue => e
        puts "Upload error: #{e.message}"
        res.status = 500
        res.body = { error: 'Upload failed', message: e.message }.to_json
      end
    end
  end

  def handle_file_upload(req, res)
    # Simple file upload handling (in production, use proper multipart parser)
    doc_id = @documents.length + 1
    filename = "document_#{doc_id}.pdf"
    
    # Create document record
    document = {
      id: doc_id,
      filename: filename,
      original_filename: "uploaded_document.pdf",
      status: 'uploaded',
      file_size: rand(1000000..5000000), # Mock file size
      content_type: 'application/pdf',
      created_at: Time.now.iso8601,
      updated_at: Time.now.iso8601,
      metadata: {
        pages: rand(50..500),
        language: 'en',
        document_type: 'legal_contract'
      },
      processing_log: [
        {
          timestamp: Time.now.iso8601,
          event: 'document_uploaded',
          message: 'Document successfully uploaded to secure storage'
        }
      ]
    }
    
    @documents << document
    
    # Start processing simulation
    start_document_processing(doc_id)
    
    res.body = {
      id: doc_id,
      filename: filename,
      status: 'uploaded',
      message: 'Document uploaded successfully and queued for processing'
    }.to_json
  end

  def handle_json_upload(req, res)
    data = JSON.parse(req.body)
    
    doc_id = @documents.length + 1
    filename = data['filename'] || "document_#{doc_id}.pdf"
    
    document = {
      id: doc_id,
      filename: filename,
      original_filename: filename,
      status: 'uploaded',
      file_size: data['size'] || rand(1000000..5000000),
      content_type: data['type'] || 'application/pdf',
      created_at: Time.now.iso8601,
      updated_at: Time.now.iso8601,
      metadata: {
        pages: rand(50..500),
        language: 'en',
        document_type: detect_document_type(filename)
      },
      processing_log: [
        {
          timestamp: Time.now.iso8601,
          event: 'document_uploaded',
          message: 'Document successfully uploaded to secure storage'
        }
      ]
    }
    
    @documents << document
    start_document_processing(doc_id)
    
    res.body = format_document(document).to_json
  end

  def handle_document_detail(req, res, method, doc_id)
    res['Content-Type'] = 'application/json'
    
    case method
    when 'GET'
      document = @documents.find { |d| d[:id] == doc_id.to_i }
      if document
        res.body = format_document(document).to_json
      else
        res.status = 404
        res.body = { error: 'Document not found' }.to_json
      end
      
    when 'DELETE'
      begin
        # Delete from database
        db = SQLite3::Database.new('storage/legastream.db')
        
        # First, delete associated entities
        db.execute('DELETE FROM entities WHERE document_id = ?', [doc_id.to_i])
        
        # Then delete the document
        result = db.execute('DELETE FROM documents WHERE id = ?', [doc_id.to_i])
        
        db.close
        
        # Also remove from in-memory array
        @documents.reject! { |d| d[:id] == doc_id.to_i }
        
        res.body = { message: 'Document deleted successfully' }.to_json
      rescue => e
        puts "Error deleting document: #{e.message}"
        res.status = 500
        res.body = { error: 'Failed to delete document', details: e.message }.to_json
      end
      
    else
      res.status = 405
      res.body = { error: 'Method not allowed' }.to_json
    end
  end

  def handle_document_analyze(req, res, doc_id)
    res['Content-Type'] = 'application/json'
    document = @documents.find { |d| d[:id] == doc_id.to_i }
    
    if document
      # Trigger analysis
      start_document_analysis(doc_id.to_i)
      
      res.body = {
        document_id: doc_id.to_i,
        status: 'analysis_started',
        message: 'Advanced AI analysis has been initiated'
      }.to_json
    else
      res.status = 404
      res.body = { error: 'Document not found' }.to_json
    end
  end

  def handle_document_status(req, res, doc_id)
    res['Content-Type'] = 'application/json'
    document = @documents.find { |d| d[:id] == doc_id.to_i }
    
    if document
      res.body = {
        id: document[:id],
        status: document[:status],
        progress: calculate_progress(document),
        processing_log: document[:processing_log] || [],
        analysis_results: document[:analysis_results] || {}
      }.to_json
    else
      res.status = 404
      res.body = { error: 'Document not found' }.to_json
    end
  end

  def handle_document_entities(req, res, doc_id)
    res['Content-Type'] = 'application/json'
    
    begin
      # Connect to database
      db = SQLite3::Database.new('storage/legastream.db')
      db.results_as_hash = true
      
      # Get document to verify it exists and belongs to user
      document = db.execute('SELECT * FROM documents WHERE id = ?', [doc_id.to_i]).first
      
      unless document
        res.status = 404
        res.body = { error: 'Document not found' }.to_json
        db.close
        return
      end
      
      # Get all entities for this document
      entities = db.execute('SELECT * FROM entities WHERE document_id = ? ORDER BY id', [doc_id.to_i])
      
      db.close
      
      # Return entities
      res.body = {
        document_id: doc_id.to_i,
        total_entities: entities.length,
        entities: entities.map { |e| {
          id: e['id'],
          entity_type: e['entity_type'],
          entity_value: e['entity_value'],
          context: e['context'],
          confidence: e['confidence']
        }}
      }.to_json
    rescue => e
      puts "Error fetching entities: #{e.message}"
      res.status = 500
      res.body = { error: 'Failed to fetch entities', details: e.message }.to_json
    end
  end

  def handle_stats(req, res)
    res['Content-Type'] = 'application/json'
    
    total_docs = @documents.length
    completed_docs = @documents.count { |d| d[:status] == 'completed' }
    processing_docs = @documents.count { |d| d[:status] == 'processing' }
    
    res.body = {
      documents_processed: total_docs,
      processing_time_saved: "#{total_docs * 2.5}h",
      ai_accuracy_rate: "98.7%",
      issues_flagged: @documents.sum { |d| (d[:analysis_results] || {})[:issues_count] || 0 },
      system_status: {
        ai_engine: 'operational',
        document_processing: processing_docs > 0 ? 'active' : 'idle',
        security_sandbox: 'secure',
        live_terminal: 'streaming'
      },
      usage_stats: {
        tokens_used: rand(2000000..2500000),
        tokens_limit: 3500000,
        usage_percentage: rand(65..75)
      }
    }.to_json
  end

  def start_document_processing(doc_id)
    Thread.new do
      document = @documents.find { |d| d[:id] == doc_id }
      return unless document
      
      # Simulate processing stages
      processing_stages = [
        { status: 'processing', message: 'Initializing document analysis...', duration: 2 },
        { status: 'processing', message: 'Extracting text and metadata...', duration: 3 },
        { status: 'processing', message: 'Identifying legal entities...', duration: 4 },
        { status: 'processing', message: 'Analyzing document structure...', duration: 3 },
        { status: 'processing', message: 'Running compliance checks...', duration: 5 },
        { status: 'completed', message: 'Document processing completed successfully', duration: 1 }
      ]
      
      processing_stages.each_with_index do |stage, index|
        sleep(stage[:duration])
        
        document[:status] = stage[:status]
        document[:updated_at] = Time.now.iso8601
        document[:processing_log] << {
          timestamp: Time.now.iso8601,
          event: 'processing_update',
          message: stage[:message],
          progress: ((index + 1) * 100 / processing_stages.length)
        }
        
        if stage[:status] == 'completed'
          document[:analysis_results] = generate_analysis_results(document)
        end
        
        puts "[PROCESSING] Doc #{doc_id}: #{stage[:message]}"
      end
    end
  end

  def start_document_analysis(doc_id)
    Thread.new do
      document = @documents.find { |d| d[:id] == doc_id }
      return unless document
      
      sleep(2)
      
      # Enhanced analysis results
      document[:analysis_results] = generate_enhanced_analysis_results(document)
      document[:processing_log] << {
        timestamp: Time.now.iso8601,
        event: 'analysis_completed',
        message: 'Advanced AI analysis completed with high confidence'
      }
      
      puts "[ANALYSIS] Doc #{doc_id}: Advanced analysis completed"
    end
  end

  def generate_analysis_results(document)
    {
      entities_extracted: rand(15..45),
      case_citations: rand(3..12),
      statutes_found: rand(2..8),
      parties_identified: rand(2..6),
      compliance_score: (rand(85..99) / 100.0).round(3),
      issues_flagged: rand(0..5),
      confidence_score: (rand(92..99) / 100.0).round(3),
      processing_time: rand(45..180),
      document_type: detect_document_type(document[:filename]),
      key_findings: generate_key_findings(),
      risk_assessment: generate_risk_assessment()
    }
  end

  def generate_enhanced_analysis_results(document)
    base_results = document[:analysis_results] || generate_analysis_results(document)
    
    base_results.merge({
      advanced_insights: {
        contract_terms: generate_contract_terms(),
        compliance_gaps: generate_compliance_gaps(),
        recommendations: generate_recommendations(),
        similar_documents: rand(3..8)
      },
      ai_confidence: (rand(95..99) / 100.0).round(3),
      analysis_depth: 'comprehensive'
    })
  end

  def generate_key_findings
    findings = [
      "Standard confidentiality clause detected",
      "Termination conditions clearly defined",
      "Intellectual property rights specified",
      "Liability limitations present",
      "Governing law jurisdiction identified"
    ]
    findings.sample(rand(2..4))
  end

  def generate_risk_assessment
    risks = ["Low", "Medium", "High"]
    {
      overall_risk: risks.sample,
      compliance_risk: risks.sample,
      financial_risk: risks.sample,
      operational_risk: risks.sample
    }
  end

  def generate_contract_terms
    [
      "Payment terms: Net 30 days",
      "Contract duration: 24 months",
      "Renewal clause: Automatic",
      "Termination notice: 30 days"
    ].sample(rand(2..3))
  end

  def generate_compliance_gaps
    gaps = [
      "GDPR data retention clause needs review",
      "Force majeure provision could be strengthened",
      "Dispute resolution mechanism unclear"
    ]
    gaps.sample(rand(0..2))
  end

  def generate_recommendations
    [
      "Consider adding specific performance metrics",
      "Review indemnification clauses",
      "Clarify intellectual property ownership",
      "Add data security requirements"
    ].sample(rand(1..3))
  end

  def detect_document_type(filename)
    case filename.downcase
    when /contract|agreement/
      'contract'
    when /policy|privacy/
      'policy'
    when /employment|hr/
      'employment'
    when /nda|confidential/
      'nda'
    else
      'legal_document'
    end
  end

  def format_document(document)
    {
      id: document[:id],
      filename: document[:filename],
      original_filename: document[:original_filename],
      status: document[:status],
      file_size: document[:file_size],
      content_type: document[:content_type],
      created_at: document[:created_at],
      updated_at: document[:updated_at],
      metadata: document[:metadata],
      analysis_results: document[:analysis_results],
      processing_log: document[:processing_log]&.last(5) # Only return last 5 log entries
    }
  end

  def calculate_progress(document)
    case document[:status]
    when 'uploaded' then 10
    when 'processing' then rand(20..90)
    when 'completed' then 100
    when 'error' then 0
    else 0
    end
  end

  def start
    puts "🚀 LegaStream Enhanced Backend Server starting on port #{@port}"
    puts "📊 Health check: http://localhost:#{@port}/up"
    puts "🔧 API endpoints: http://localhost:#{@port}/api/v1/*"
    puts "📄 Document processing: ACTIVE"
    puts "🤖 AI analysis engine: READY"
    puts "🛑 Press Ctrl+C to stop"
    
    trap('INT') { 
      puts "\n🛑 Shutting down server..."
      @server.shutdown 
    }
    
    @server.start
  end
end

# Start the enhanced server
if __FILE__ == $0
  server = LegaStreamServer.new(6000)
  server.start
end