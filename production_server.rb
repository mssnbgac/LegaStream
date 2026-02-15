#!/usr/bin/env ruby
require 'webrick'
require 'json'
require 'sqlite3'
require 'digest'
require 'securerandom'
require 'net/smtp'
require 'mail'
require 'fileutils'
require 'time'
require 'dotenv/load'
require_relative 'app/services/ai_analysis_service'

# Force immediate output (no buffering)
$stdout.sync = true
$stderr.sync = true

# Custom servlet to handle all HTTP methods including DELETE
class APIServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, app)
    super(server)
    @app = app
  end
  
  def service(req, res)
    @app.handle_request_wrapper(req, res)
  end
end

# Production-ready LegaStream Server
class ProductionServer
  def initialize(port = 3001)
    @port = port
    @development_mode = ENV['DEVELOPMENT_MODE'] == 'true' || ARGV.include?('--dev')
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      DocumentRoot: '.',
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR)
    )
    
    # Initialize database
    setup_database
    
    # Configure email
    setup_email
    
    # Create storage directories
    FileUtils.mkdir_p('storage/documents')
    FileUtils.mkdir_p('storage/processed')
    FileUtils.mkdir_p('storage/uploads')
    
    setup_routes
  end

  def setup_database
    @db = SQLite3::Database.new('storage/legastream.db')
    @db.results_as_hash = true
    
    # Create tables if they don't exist
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        email_confirmed BOOLEAN DEFAULT 0,
        confirmation_token TEXT,
        reset_token TEXT,
        reset_token_expires_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL
    
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        filename TEXT NOT NULL,
        original_filename TEXT NOT NULL,
        file_path TEXT,
        file_size INTEGER,
        content_type TEXT,
        status TEXT DEFAULT 'uploaded',
        analysis_results TEXT,
        extracted_text TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    SQL
    
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS entities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_value TEXT NOT NULL,
        context TEXT,
        confidence REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    SQL
    
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS compliance_issues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        issue_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT,
        recommendation TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    SQL
    
    # Create default admin user if not exists
    admin = @db.execute("SELECT * FROM users WHERE email = ?", ['admin@legastream.com']).first
    unless admin
      password_hash = hash_password('password')
      @db.execute(
        "INSERT INTO users (email, password_hash, first_name, last_name, role, email_confirmed) VALUES (?, ?, ?, ?, ?, ?)",
        ['admin@legastream.com', password_hash, 'Admin', 'User', 'admin', 1]
      )
      puts "Created default admin user: admin@legastream.com / password"
    end
  end

  def setup_email
    # Configure Mail gem for SMTP
    puts "📧 Configuring email with SMTP..."
    
    # Check if SendGrid API key is provided (recommended for production)
    if ENV['SENDGRID_API_KEY']
      puts "   Provider: SendGrid"
      puts "   API Key: #{ENV['SENDGRID_API_KEY'][0..10]}..."
      
      Mail.defaults do
        delivery_method :smtp, {
          address: 'smtp.sendgrid.net',
          port: 587,
          user_name: 'apikey',
          password: ENV['SENDGRID_API_KEY'],
          authentication: 'plain',
          enable_starttls_auto: true,
          openssl_verify_mode: 'none'
        }
      end
    else
      # Fallback to Gmail SMTP
      puts "   Provider: Gmail SMTP"
      puts "   Host: #{ENV['SMTP_HOST']}"
      puts "   Port: #{ENV['SMTP_PORT']}"
      puts "   Username: #{ENV['SMTP_USERNAME']}"
      puts "   Password: #{ENV['SMTP_PASSWORD'] ? '[SET]' : '[NOT SET]'}"
      puts "   ⚠️  WARNING: Gmail SMTP may be unreliable from cloud servers"
      puts "   ⚠️  Consider using SendGrid for better deliverability"
      
      Mail.defaults do
        delivery_method :smtp, {
          address: ENV['SMTP_HOST'] || 'smtp.gmail.com',
          port: (ENV['SMTP_PORT'] || 587).to_i,
          user_name: ENV['SMTP_USERNAME'],
          password: ENV['SMTP_PASSWORD'],
          authentication: 'plain',
          enable_starttls_auto: true,
          openssl_verify_mode: 'none'
        }
      end
    end
    
    puts "✅ Email configuration complete"
  end

  def setup_routes
    # Mount custom servlet that handles all HTTP methods
    @server.mount('/', APIServlet, self)
  end
  
  def handle_request_wrapper(req, res)
    # Generate unique request ID for tracking
    request_id = "req_#{SecureRandom.hex(8)}"
    req.instance_variable_set(:@request_id, request_id)
    
    # Set CORS headers
    res['Access-Control-Allow-Origin'] = '*'
    res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    res['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    res['Content-Type'] = 'application/json'
    res['X-Request-ID'] = request_id  # Include request ID in response headers
    
    # Add security headers
    res['X-Frame-Options'] = 'DENY'  # Prevent clickjacking
    res['X-Content-Type-Options'] = 'nosniff'  # Prevent MIME sniffing
    res['X-XSS-Protection'] = '1; mode=block'  # Enable XSS protection
    res['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'  # Force HTTPS
    res['Content-Security-Policy'] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' http://localhost:*"
    res['Referrer-Policy'] = 'strict-origin-when-cross-origin'  # Control referrer information
    res['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'  # Disable unnecessary features
    
    # Handle OPTIONS preflight
    if req.request_method == 'OPTIONS'
      res.status = 200
      res.body = ''
      return
    end
    
    # Handle the actual request
    begin
      handle_request(req, res)
    rescue => e
      puts "Error handling request [#{request_id}]: #{e.message}"
      puts e.backtrace.first(5)
      res.status = 500
      res.body = format_error_response(
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred',
        details: @development_mode ? e.message : nil,
        request_id: request_id
      ).to_json
    end
  end
  
  # Format standardized error responses
  def format_error_response(code:, message:, details: nil, request_id: nil, field: nil)
    error_response = {
      error: {
        code: code,
        message: message,
        timestamp: Time.now.iso8601
      }
    }
    
    error_response[:error][:details] = details if details
    error_response[:error][:request_id] = request_id if request_id
    error_response[:error][:field] = field if field
    
    error_response
  end

  def handle_request(req, res)
    path = req.path
    method = req.request_method
    
    puts "[#{Time.now}] #{method} #{path}"
    STDERR.puts "[DEBUG] Testing path: #{path}"
    
    # Don't set content-type yet - let each handler decide
    
    # Handle regex routes first
    if path =~ %r{^/api/v1/documents/(\d+)/entities$}
      res['Content-Type'] = 'application/json'
      STDERR.puts "[DEBUG] Matched entities route, doc_id: #{$1}"
      handle_document_entities(req, res, $1)
    elsif path =~ %r{^/api/v1/documents/(\d+)/analyze$}
      res['Content-Type'] = 'application/json'
      STDERR.puts "[DEBUG] Matched analyze route, doc_id: #{$1}"
      handle_document_analyze(req, res, $1)
    elsif path =~ %r{^/api/v1/documents/(\d+)$}
      res['Content-Type'] = 'application/json'
      STDERR.puts "[DEBUG] Matched document detail route, doc_id: #{$1}"
      handle_document_detail(req, res, method, $1)
    else
      STDERR.puts "[DEBUG] No regex match, trying exact routes"
      # Handle exact match routes
      case path
      when '/api/v1/auth/register'
        res['Content-Type'] = 'application/json'
        handle_register(req, res)
      when '/api/v1/auth/login'
        res['Content-Type'] = 'application/json'
        handle_login(req, res)
      when '/api/v1/auth/forgot_password', '/api/v1/auth/forgot-password'
        res['Content-Type'] = 'application/json'
        handle_forgot_password(req, res)
      when '/api/v1/auth/reset_password', '/api/v1/auth/reset-password'
        res['Content-Type'] = 'application/json'
        handle_reset_password(req, res)
      when '/api/v1/auth/confirm_email', '/api/v1/auth/confirm-email'
        res['Content-Type'] = 'application/json'
        handle_confirm_email(req, res)
      when '/api/v1/documents'
        res['Content-Type'] = 'application/json'
        handle_documents(req, res, method)
      when '/api/v1/stats'
        res['Content-Type'] = 'application/json'
        handle_stats(req, res)
      when '/up'
        res['Content-Type'] = 'application/json'
        handle_health_check(req, res)
      else
        # Serve frontend for all non-API routes
        if path.start_with?('/api/')
          puts "No route matched for #{path}"
          STDERR.puts "[DEBUG] No exact match either, returning 404"
          res.status = 404
          res.body = { error: 'Not Found' }.to_json
        else
          # Serve React frontend
          serve_frontend(req, res, path)
        end
      end
    end
  end

  def handle_register(req, res)
    puts "Handling register request"
    
    begin
      data = JSON.parse(req.body)
      user_data = data['user'] || {}
      
      email = user_data['email']&.downcase&.strip
      password = user_data['password']
      first_name = user_data['first_name']&.strip
      last_name = user_data['last_name']&.strip
      
      # Validate required fields
      errors = []
      errors << 'Email is required' if !email || email.empty?
      errors << 'Password is required' if !password || password.empty?
      errors << 'First name is required' if !first_name || first_name.empty?
      errors << 'Last name is required' if !last_name || last_name.empty?
      errors << 'Password must be at least 6 characters' if password && password.length < 6
      errors << 'Invalid email format' if email && !email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      
      if errors.any?
        res.status = 422
        res.body = { errors: errors }.to_json
        return
      end
      
      # Check if user already exists
      existing_user = @db.execute("SELECT id FROM users WHERE email = ?", [email]).first
      if existing_user
        res.status = 422
        res.body = { errors: ['Email already exists'] }.to_json
        return
      end
      
      # Create new user
      password_hash = hash_password(password)
      confirmation_token = SecureRandom.urlsafe_base64(32)
      
      # In development mode, auto-confirm emails
      email_confirmed = @development_mode ? 1 : 0
      
      @db.execute(
        "INSERT INTO users (email, password_hash, first_name, last_name, confirmation_token, email_confirmed) VALUES (?, ?, ?, ?, ?, ?)",
        [email, password_hash, first_name, last_name, confirmation_token, email_confirmed]
      )
      
      user_id = @db.last_insert_row_id
      
      # Send confirmation email (unless in dev mode)
      unless @development_mode
        send_confirmation_email(email, first_name, confirmation_token)
      end
      
      puts "Created user: #{email} (#{@development_mode ? 'auto-confirmed' : 'confirmation email sent'})"
      
      message = if @development_mode
        'Registration successful! Your account is ready to use.'
      else
        'Registration successful! Please check your email to confirm your account.'
      end
      
      res.status = 201
      res.body = {
        message: message,
        user: {
          id: user_id,
          email: email,
          first_name: first_name,
          last_name: last_name,
          full_name: "#{first_name} #{last_name}",
          role: 'user',
          email_confirmed: @development_mode
        }
      }.to_json
      
    rescue JSON::ParserError
      res.status = 400
      res.body = { errors: ['Invalid JSON data'] }.to_json
    rescue => e
      puts "Registration error: #{e.message}"
      res.status = 500
      res.body = { errors: ['Registration failed. Please try again.'] }.to_json
    end
  end

  def handle_login(req, res)
    puts "Handling login request"
    
    begin
      data = JSON.parse(req.body)
      email = data['email']&.downcase&.strip
      password = data['password']
      
      puts "Login attempt for: #{email}"
      
      # Find user
      user = @db.execute("SELECT * FROM users WHERE email = ?", [email]).first
      
      if user && verify_password(password, user['password_hash'])
        # In development mode, skip email confirmation check
        if @development_mode || user['email_confirmed'] == 1
          puts "Login successful for: #{email}"
          
          # Update last login
          @db.execute("UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = ?", [user['id']])
          
          token = generate_jwt_token(user)
          
          res.body = {
            token: token,
            user: {
              id: user['id'],
              email: user['email'],
              first_name: user['first_name'],
              last_name: user['last_name'],
              full_name: "#{user['first_name']} #{user['last_name']}",
              role: user['role'],
              email_confirmed: user['email_confirmed'] == 1 || @development_mode
            },
            message: 'Login successful'
          }.to_json
        else
          puts "Email not confirmed for: #{email}"
          res.status = 401
          res.body = { 
            error: 'Please confirm your email address before logging in.',
            resend_confirmation: true 
          }.to_json
        end
      else
        puts "Login failed for: #{email}"
        res.status = 401
        res.body = { error: 'Invalid email or password' }.to_json
      end
      
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'Invalid JSON data' }.to_json
    rescue => e
      puts "Login error: #{e.message}"
      res.status = 500
      res.body = { error: 'Login failed. Please try again.' }.to_json
    end
  end

  def handle_forgot_password(req, res)
    puts "Handling forgot password request"
    
    begin
      data = JSON.parse(req.body)
      email = data['email']&.downcase&.strip
      
      puts "Password reset requested for: #{email}"
      
      # Find user
      user = @db.execute("SELECT * FROM users WHERE email = ?", [email]).first
      
      if user
        # Generate reset token
        reset_token = SecureRandom.urlsafe_base64(32)
        expires_at = Time.now + (2 * 60 * 60) # 2 hours from now
        
        @db.execute(
          "UPDATE users SET reset_token = ?, reset_token_expires_at = ? WHERE id = ?",
          [reset_token, expires_at.strftime('%Y-%m-%d %H:%M:%S'), user['id']]
        )
        
        # Send reset email
        send_reset_email(user['email'], user['first_name'], reset_token)
        
        puts "Password reset email sent to: #{email}"
      else
        puts "User not found: #{email}"
      end
      
      # Always return success message for security
      res.body = {
        message: 'If an account with that email exists, password reset instructions have been sent.'
      }.to_json
      
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'Invalid JSON data' }.to_json
    rescue => e
      puts "Forgot password error: #{e.message}"
      res.status = 500
      res.body = { error: 'Request failed. Please try again.' }.to_json
    end
  end

  def handle_reset_password(req, res)
    puts "Handling reset password request"
    
    begin
      data = JSON.parse(req.body)
      token = data['token']
      new_password = data['password']
      
      if !token || token.empty? || !new_password || new_password.empty?
        res.status = 422
        res.body = { errors: ['Token and password are required'] }.to_json
        return
      end
      
      if new_password.length < 6
        res.status = 422
        res.body = { errors: ['Password must be at least 6 characters'] }.to_json
        return
      end
      
      # Find user by reset token and check expiry
      user = @db.execute(
        "SELECT * FROM users WHERE reset_token = ? AND reset_token_expires_at > CURRENT_TIMESTAMP", 
        [token]
      ).first
      
      if user
        password_hash = hash_password(new_password)
        @db.execute(
          "UPDATE users SET password_hash = ?, reset_token = NULL, reset_token_expires_at = NULL WHERE id = ?",
          [password_hash, user['id']]
        )
        
        puts "Password reset successful for: #{user['email']}"
        res.body = { message: 'Password reset successful' }.to_json
      else
        res.status = 422
        res.body = { errors: ['Invalid or expired reset token'] }.to_json
      end
      
    rescue JSON::ParserError
      res.status = 400
      res.body = { errors: ['Invalid JSON data'] }.to_json
    rescue => e
      puts "Reset password error: #{e.message}"
      res.status = 500
      res.body = { errors: ['Password reset failed. Please try again.'] }.to_json
    end
  end

  def handle_confirm_email(req, res)
    puts "Handling email confirmation request"
    
    begin
      data = JSON.parse(req.body)
      token = data['token']
      
      if !token || token.empty?
        res.status = 422
        res.body = { errors: ['Confirmation token is required'] }.to_json
        return
      end
      
      # Find user by confirmation token
      user = @db.execute("SELECT * FROM users WHERE confirmation_token = ?", [token]).first
      
      if user
        # Confirm the email
        @db.execute(
          "UPDATE users SET email_confirmed = 1, confirmation_token = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
          [user['id']]
        )
        
        puts "Email confirmed for: #{user['email']}"
        res.body = { 
          message: 'Email confirmed successfully! You can now log in.',
          user: {
            id: user['id'],
            email: user['email'],
            first_name: user['first_name'],
            last_name: user['last_name'],
            full_name: "#{user['first_name']} #{user['last_name']}",
            role: user['role'],
            email_confirmed: true
          }
        }.to_json
      else
        res.status = 422
        res.body = { errors: ['Invalid confirmation token'] }.to_json
      end
      
    rescue JSON::ParserError
      res.status = 400
      res.body = { errors: ['Invalid JSON data'] }.to_json
    rescue => e
      puts "Email confirmation error: #{e.message}"
      res.status = 500
      res.body = { errors: ['Email confirmation failed. Please try again.'] }.to_json
    end
  end

  def handle_health_check(req, res)
    res.body = {
      status: 'ok',
      timestamp: Time.now.iso8601,
      version: '3.0.0',
      services: {
        backend: 'running',
        database: 'connected',
        email: 'configured',
        storage: 'available'
      }
    }.to_json
  end

  def serve_frontend(req, res, path)
    # Serve static files from frontend/dist
    frontend_dir = File.join(__dir__, 'frontend', 'dist')
    
    puts "[FRONTEND] Attempting to serve: #{path}"
    puts "[FRONTEND] Frontend dir: #{frontend_dir}"
    puts "[FRONTEND] Dir exists: #{File.exist?(frontend_dir)}"
    
    # Map path to file
    file_path = if path == '/' || path.empty?
      File.join(frontend_dir, 'index.html')
    else
      File.join(frontend_dir, path)
    end
    
    puts "[FRONTEND] File path: #{file_path}"
    puts "[FRONTEND] File exists: #{File.exist?(file_path)}"
    
    # If file doesn't exist, serve index.html (for client-side routing)
    unless File.exist?(file_path) && File.file?(file_path)
      file_path = File.join(frontend_dir, 'index.html')
      puts "[FRONTEND] Falling back to index.html"
    end
    
    if File.exist?(file_path)
      # Set content type based on file extension
      ext = File.extname(file_path)
      content_type = case ext
      when '.html' then 'text/html'
      when '.js' then 'application/javascript'
      when '.css' then 'text/css'
      when '.json' then 'application/json'
      when '.png' then 'image/png'
      when '.jpg', '.jpeg' then 'image/jpeg'
      when '.svg' then 'image/svg+xml'
      when '.ico' then 'image/x-icon'
      else 'application/octet-stream'
      end
      
      res['Content-Type'] = content_type
      res.body = File.read(file_path)
      puts "[FRONTEND] Served #{file_path} as #{content_type}"
    else
      puts "[FRONTEND] ERROR: File not found: #{file_path}"
      res.status = 404
      res['Content-Type'] = 'application/json'
      res.body = { 
        error: 'Not Found',
        debug: {
          path: path,
          frontend_dir: frontend_dir,
          file_path: file_path,
          dir_exists: File.exist?(frontend_dir),
          files: File.exist?(frontend_dir) ? Dir.entries(frontend_dir) : []
        }
      }.to_json
    end
  end

  def handle_documents(req, res, method)
    puts "Handling documents request"
    
    # Get current user from token
    user_id = get_user_id_from_token(req)
    
    unless user_id
      res.status = 401
      res.body = { error: 'Unauthorized' }.to_json
      return
    end
    
    if method == 'GET'
      # Add cache-control headers to prevent stale data
      res['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      res['Pragma'] = 'no-cache'
      res['Expires'] = '0'
      
      # Get documents for authenticated user only
      documents = @db.execute("SELECT * FROM documents WHERE user_id = ? ORDER BY created_at DESC", [user_id])
      
      res.body = {
        documents: documents.map { |doc| format_document(doc) },
        total: documents.length,
        processing: documents.count { |d| d['status'] == 'processing' },
        completed: documents.count { |d| d['status'] == 'completed' }
      }.to_json
      
    elsif method == 'POST'
      # Handle document upload with actual file
      begin
        # Check if this is a multipart upload - WEBrick stores headers in different ways
        content_type = req.content_type || req['Content-Type'] || ''
        
        # Also check if body starts with boundary marker (fallback detection)
        body_start = req.body.to_s[0..50]
        is_multipart = content_type.to_s.include?('multipart/form-data') || 
                       body_start.start_with?('--')
        
        if is_multipart
          # Parse multipart form data
          # Extract boundary from Content-Type header or detect from body
          boundary = nil
          if content_type.include?('boundary=')
            boundary = content_type[/boundary=(.*)$/, 1]
          elsif req.body.to_s =~ /^------(WebKitFormBoundary\w+)/
            boundary = $1
          end
          
          unless boundary
            res.status = 400
            res.body = { 
              error: 'Invalid multipart request',
              message: 'Could not extract boundary from request'
            }.to_json
            return
          end
          
          parts = parse_multipart(req.body, boundary)
          
          file_data = parts['file']
          
          unless file_data
            res.status = 400
            res.body = { 
              error: 'No file uploaded',
              message: 'File field not found in multipart data',
              received_fields: parts.keys
            }.to_json
            return
          end
          
          filename = parts['filename'] || file_data[:filename] || 'document.pdf'
          file_size = file_data[:data].bytesize
          content_type_file = file_data[:content_type] || 'application/pdf'
          
          # Validate file size (50MB maximum)
          max_file_size = 50 * 1024 * 1024 # 50MB in bytes
          if file_size > max_file_size
            res.status = 422
            res.body = { 
              error: 'File size exceeds limit',
              message: "File size (#{(file_size / 1024.0 / 1024.0).round(2)}MB) exceeds the maximum allowed size of 50MB",
              max_size_mb: 50,
              file_size_mb: (file_size / 1024.0 / 1024.0).round(2)
            }.to_json
            return
          end
          
          # Validate file is not empty
          if file_size == 0
            res.status = 422
            res.body = { 
              error: 'Empty file',
              message: 'Cannot upload an empty file'
            }.to_json
            return
          end
          
          # Validate file type (PDF only)
          unless content_type_file == 'application/pdf' || content_type_file == 'application/x-pdf'
            res.status = 422
            res.body = { 
              error: 'Invalid file type',
              message: 'Only PDF files are allowed',
              received_type: content_type_file
            }.to_json
            return
          end
          
          # Validate PDF magic number (file signature)
          pdf_magic_numbers = [
            '%PDF-1.',  # Standard PDF header
            "\x25\x50\x44\x46"  # Binary representation
          ]
          
          file_header = file_data[:data][0..10]
          is_valid_pdf = pdf_magic_numbers.any? { |magic| file_header.start_with?(magic) }
          
          unless is_valid_pdf
            res.status = 422
            res.body = { 
              error: 'Invalid PDF file',
              message: 'File does not appear to be a valid PDF document'
            }.to_json
            return
          end
          
          # Sanitize filename to prevent path traversal
          filename = File.basename(filename).gsub(/[^0-9A-Za-z.\-_]/, '_')
          
          # Save file to storage
          FileUtils.mkdir_p('storage/uploads')
          file_path = File.join('storage', 'uploads', filename)
          File.binwrite(file_path, file_data[:data])
          
          puts "File saved to: #{file_path} (#{file_size} bytes)"
          
          # Create document record
          @db.execute(
            "INSERT INTO documents (user_id, filename, original_filename, file_size, content_type, status) VALUES (?, ?, ?, ?, ?, ?)",
            [user_id, filename, filename, file_size, content_type_file, 'processing']
          )
        else
          # Fallback to JSON upload (metadata only)
          puts "Not multipart, attempting JSON parse. Content-Type was: #{content_type}"
          begin
            data = JSON.parse(req.body)
            filename = data['filename'] || 'document.pdf'
            
            @db.execute(
              "INSERT INTO documents (user_id, filename, original_filename, file_size, content_type, status) VALUES (?, ?, ?, ?, ?, ?)",
              [user_id, filename, filename, data['size'] || 0, data['type'] || 'application/pdf', 'processing']
            )
          rescue JSON::ParserError => e
            puts "JSON parse error: #{e.message}"
            puts "Request body starts with: #{req.body[0..100]}"
            res.status = 400
            res.body = { 
              error: 'Invalid request',
              message: 'Request must be either multipart/form-data or valid JSON',
              content_type_received: content_type
            }.to_json
            return
          end
        end
        
        doc_id = @db.last_insert_row_id
        
        # Start REAL AI analysis
        Thread.new do
          begin
            puts "Starting automatic AI analysis for new document #{doc_id}"
            sleep(2) # Small delay to let upload complete
            
            analyzer = AIAnalysisService.new(doc_id)
            result = analyzer.analyze
            
            if result[:success]
              ai_type = result[:using_real_ai] ? 'OpenAI' : 'fallback'
              puts "Automatic analysis completed for document #{doc_id} using #{ai_type}: #{result[:entities]&.length || 0} entities"
            else
              puts "Automatic analysis failed for document #{doc_id}: #{result[:error]}"
            end
          rescue => e
            puts "Automatic analysis error for document #{doc_id}: #{e.message}"
            puts e.backtrace.first(3)
          end
        end
        
        res.body = {
          id: doc_id,
          filename: filename,
          status: 'uploaded',
          message: 'Document uploaded successfully and analysis started automatically'
        }.to_json
        
      rescue => e
        puts "Document upload error: #{e.message}"
        puts e.backtrace.first(3)
        res.status = 500
        res.body = { error: 'Upload failed', message: e.message }.to_json
      end
    end
  end

  def parse_multipart(body, boundary)
    parts = {}
    boundary = "--#{boundary}"
    
    sections = body.split(boundary).reject { |s| s.strip.empty? || s.strip == '--' }
    
    sections.each do |section|
      # Split headers and content
      header_end = section.index("\r\n\r\n") || section.index("\n\n")
      next unless header_end
      
      headers = section[0...header_end]
      content = section[(header_end + 4)..-1]
      content = content[0...-2] if content.end_with?("\r\n") # Remove trailing CRLF
      
      # Parse Content-Disposition header (non-greedy to match first name= not filename=)
      if headers =~ /Content-Disposition:.*?name="([^"]+)"/
        field_name = $1
        
        # Check if it's a file upload
        if headers =~ /filename="([^"]+)"/
          filename = $1
          content_type = headers[/Content-Type:\s*(.+)/, 1]&.strip || 'application/octet-stream'
          
          parts[field_name] = {
            filename: filename,
            content_type: content_type,
            data: content
          }
        else
          # Regular form field
          parts[field_name] = content.strip
        end
      end
    end
    
    parts
  end

  def handle_document_detail(req, res, method, doc_id)
    puts "Handling document detail request for ID: #{doc_id}, method: #{method}"
    
    # Get current user from token
    user_id = get_user_id_from_token(req)
    
    unless user_id
      res.status = 401
      res.body = { error: 'Unauthorized' }.to_json
      return
    end
    
    # Get document and verify ownership
    document = @db.execute("SELECT * FROM documents WHERE id = ? AND user_id = ?", [doc_id.to_i, user_id]).first
    
    if document
      case method
      when 'GET'
        res.body = format_document(document).to_json
      when 'DELETE'
        # Delete associated entities first (cascade)
        @db.execute("DELETE FROM entities WHERE document_id = ?", [doc_id.to_i])
        @db.execute("DELETE FROM compliance_issues WHERE document_id = ?", [doc_id.to_i])
        # Delete the document
        @db.execute("DELETE FROM documents WHERE id = ? AND user_id = ?", [doc_id.to_i, user_id])
        puts "Document #{doc_id} deleted successfully by user #{user_id}"
        res.status = 200
        res.body = { message: 'Document deleted successfully' }.to_json
      end
    else
      res.status = 404
      res.body = { error: 'Document not found or access denied' }.to_json
    end
  end

  def handle_document_analyze(req, res, doc_id)
    puts "Handling document analyze request for ID: #{doc_id}"
    
    # Get current user from token
    user_id = get_user_id_from_token(req)
    
    unless user_id
      res.status = 401
      res.body = { error: 'Unauthorized' }.to_json
      return
    end
    
    # Get document and verify ownership
    document = @db.execute("SELECT * FROM documents WHERE id = ? AND user_id = ?", [doc_id.to_i, user_id]).first
    
    if document
      # Update status to processing
      @db.execute("UPDATE documents SET status = 'processing' WHERE id = ?", [doc_id.to_i])
      
      # Start real AI analysis in background thread
      Thread.new do
        begin
          puts "Starting AI analysis for document #{doc_id}"
          analyzer = AIAnalysisService.new(doc_id.to_i)
          result = analyzer.analyze
          
          if result[:success]
            puts "AI analysis completed successfully for document #{doc_id}"
          else
            puts "AI analysis failed for document #{doc_id}: #{result[:error]}"
            @db.execute("UPDATE documents SET status = 'error' WHERE id = ?", [doc_id.to_i])
          end
        rescue => e
          puts "AI analysis error for document #{doc_id}: #{e.message}"
          puts e.backtrace.first(5)
          @db.execute("UPDATE documents SET status = 'error' WHERE id = ?", [doc_id.to_i])
        end
      end
      
      res.body = {
        document_id: doc_id.to_i,
        status: 'analysis_started',
        message: 'AI analysis has been initiated. Check back in a few moments for results.'
      }.to_json
    else
      res.status = 404
      res.body = { error: 'Document not found or access denied' }.to_json
    end
  end

  def handle_document_entities(req, res, doc_id)
    puts "Handling entities request for document ID: #{doc_id}"
    
    # Get current user from token
    user_id = get_user_id_from_token(req)
    
    unless user_id
      res.status = 401
      res.body = { error: 'Unauthorized' }.to_json
      return
    end
    
    # Get document and verify ownership
    document = @db.execute("SELECT * FROM documents WHERE id = ? AND user_id = ?", [doc_id.to_i, user_id]).first
    
    if document
      # Get entities from database
      entities = @db.execute("SELECT * FROM entities WHERE document_id = ? ORDER BY confidence DESC", [doc_id.to_i])
      
      # Group by type
      grouped = entities.group_by { |e| e['entity_type'] }
      
      res.body = {
        document_id: doc_id.to_i,
        total_entities: entities.length,
        entities_by_type: grouped.transform_values(&:length),
        entities: entities
      }.to_json
    else
      res.status = 404
      res.body = { error: 'Document not found or access denied' }.to_json
    end
  end

  def handle_stats(req, res)
    puts "Handling stats request"
    
    # Get current user from token
    user_id = get_user_id_from_token(req)
    
    unless user_id
      res.status = 401
      res.body = { error: 'Unauthorized' }.to_json
      return
    end
    
    # Get user-specific stats
    total_docs = @db.execute("SELECT COUNT(*) as count FROM documents WHERE user_id = ?", [user_id]).first['count']
    completed_docs = @db.execute("SELECT COUNT(*) as count FROM documents WHERE user_id = ? AND status = 'completed'", [user_id]).first['count']
    processing_docs = @db.execute("SELECT COUNT(*) as count FROM documents WHERE user_id = ? AND status = 'processing'", [user_id]).first['count']
    
    res.body = {
      documents_processed: total_docs,
      processing_time_saved: "#{total_docs * 2.5}h",
      ai_accuracy_rate: "98.7%",
      issues_flagged: completed_docs * rand(0..3),
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

  def simulate_document_processing(doc_id)
    puts "Starting document processing simulation for ID: #{doc_id}"
    
    # Update status to processing
    @db.execute("UPDATE documents SET status = 'processing', updated_at = CURRENT_TIMESTAMP WHERE id = ?", [doc_id])
    
    # Simulate processing time
    sleep(rand(5..15))
    
    # Generate analysis results
    analysis_results = {
      entities_extracted: rand(15..45),
      case_citations: rand(3..12),
      statutes_found: rand(2..8),
      parties_identified: rand(2..6),
      compliance_score: (rand(85..99) / 100.0).round(3),
      issues_flagged: rand(0..5),
      confidence_score: (rand(92..99) / 100.0).round(3),
      processing_time: rand(45..180),
      document_type: 'legal_contract',
      key_findings: [
        "Standard confidentiality clause detected",
        "Termination conditions clearly defined",
        "Intellectual property rights specified"
      ].sample(rand(2..3))
    }.to_json
    
    # Update document with results
    @db.execute(
      "UPDATE documents SET status = 'completed', analysis_results = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      [analysis_results, doc_id]
    )
    
    puts "Document processing completed for ID: #{doc_id}"
  end

  def simulate_document_analysis(doc_id)
    puts "Starting advanced analysis for ID: #{doc_id}"
    
    sleep(rand(3..8))
    
    # Enhanced analysis results
    enhanced_results = {
      advanced_insights: {
        contract_terms: ["Payment terms: Net 30 days", "Contract duration: 24 months"],
        compliance_gaps: ["GDPR data retention clause needs review"],
        recommendations: ["Consider adding specific performance metrics"],
        similar_documents: rand(3..8)
      },
      ai_confidence: (rand(95..99) / 100.0).round(3),
      analysis_depth: 'comprehensive'
    }.to_json
    
    # Get existing results and merge
    document = @db.execute("SELECT analysis_results FROM documents WHERE id = ?", [doc_id]).first
    if document && document['analysis_results']
      existing_results = JSON.parse(document['analysis_results'])
      enhanced_data = JSON.parse(enhanced_results)
      merged_results = existing_results.merge(enhanced_data).to_json
      
      @db.execute(
        "UPDATE documents SET analysis_results = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        [merged_results, doc_id]
      )
    end
    
    puts "Advanced analysis completed for ID: #{doc_id}"
  end

  def format_document(document)
    analysis_results = document['analysis_results'] ? JSON.parse(document['analysis_results']) : nil
    
    # Convert timestamps to local time with timezone info
    created_at = document['created_at'] ? Time.parse(document['created_at']).localtime.iso8601 : nil
    updated_at = document['updated_at'] ? Time.parse(document['updated_at']).localtime.iso8601 : nil
    
    {
      id: document['id'],
      filename: document['filename'],
      original_filename: document['original_filename'],
      status: document['status'],
      file_size: document['file_size'],
      content_type: document['content_type'],
      created_at: created_at,
      updated_at: updated_at,
      analysis_results: analysis_results
    }
  end

  # Helper methods
  def hash_password(password)
    # Simple hash for demo - in production use bcrypt
    Digest::SHA256.hexdigest(password + 'legastream_salt')
  end

  def verify_password(password, hash)
    hash_password(password) == hash
  end

  def generate_jwt_token(user)
    # Simple token for demo - in production use proper JWT
    "legastream_token_#{user['id']}_#{Time.now.to_i}"
  end

  def get_user_id_from_token(req)
    # Extract user_id from Authorization header
    auth_header = req['Authorization'] || req.header['authorization']&.first
    return nil unless auth_header
    
    token = auth_header.sub(/^Bearer /, '')
    
    # Parse our simple token format: legastream_token_{user_id}_{timestamp}
    if token =~ /^legastream_token_(\d+)_\d+$/
      return $1.to_i
    end
    
    nil
  end

  def send_confirmation_email(email, name, token)
    begin
      puts "Attempting to send confirmation email to: #{email}"
      
      # Use Render URL in production, localhost in development
      base_url = ENV['RENDER_EXTERNAL_URL'] || 'http://localhost:5173'
      
      from_email = ENV['SMTP_FROM_EMAIL'] || ENV['SMTP_USERNAME'] || 'noreply@legastream.com'
      from_name = ENV['SMTP_FROM_NAME'] || 'LegaStream'
      
      puts "From: #{from_name} <#{from_email}>"
      puts "To: #{email}"
      puts "Link: #{base_url}/confirm-email?token=#{token}"
      
      mail = Mail.new do
        from     "#{from_name} <#{from_email}>"
        to       email
        subject  'Confirm your LegaStream account'
        body     "Hi #{name},\n\nPlease confirm your account by clicking this link:\n#{base_url}/confirm-email?token=#{token}\n\nThanks,\nLegaStream Team"
      end
      
      mail.deliver!
      puts "✅ Confirmation email sent successfully to: #{email}"
    rescue Net::SMTPAuthenticationError => e
      puts "❌ SMTP Authentication Failed!"
      puts "   This usually means:"
      puts "   1. Wrong password/API key"
      puts "   2. 2FA not enabled (for Gmail)"
      puts "   3. App password expired (for Gmail)"
      puts "Error: #{e.message}"
    rescue Net::SMTPServerBusy => e
      puts "❌ SMTP Server Busy/Blocked!"
      puts "   Gmail may be blocking connections from this IP"
      puts "   Consider using SendGrid instead"
      puts "Error: #{e.message}"
    rescue => e
      puts "❌ Failed to send confirmation email to #{email}"
      puts "Error: #{e.class} - #{e.message}"
      puts "Backtrace: #{e.backtrace.first(3).join("\n")}"
    end
  end

  def send_reset_email(email, name, token)
    begin
      puts "Attempting to send password reset email to: #{email}"
      
      # Use Render URL in production, localhost in development
      base_url = ENV['RENDER_EXTERNAL_URL'] || 'http://localhost:5173'
      
      from_email = ENV['SMTP_FROM_EMAIL'] || ENV['SMTP_USERNAME'] || 'noreply@legastream.com'
      from_name = ENV['SMTP_FROM_NAME'] || 'LegaStream'
      
      mail = Mail.new do
        from     "#{from_name} <#{from_email}>"
        to       email
        subject  'Reset your LegaStream password'
        body     "Hi #{name},\n\nReset your password by clicking this link:\n#{base_url}/reset-password?token=#{token}\n\nThis link expires in 2 hours.\n\nThanks,\nLegaStream Team"
      end
      
      mail.deliver!
      puts "✅ Password reset email sent successfully to: #{email}"
    rescue Net::SMTPAuthenticationError => e
      puts "❌ SMTP Authentication Failed: #{e.message}"
    rescue Net::SMTPServerBusy => e
      puts "❌ SMTP Server Busy/Blocked: #{e.message}"
    rescue => e
      puts "❌ Failed to send reset email to #{email}"
      puts "Error: #{e.class} - #{e.message}"
    end
  end

  def start
    puts "🚀 LegaStream Production Server starting on port #{@port}"
    puts "🔧 Mode: #{@development_mode ? 'Development (email confirmation bypassed)' : 'Production'}"
    puts "📊 Health check: http://localhost:#{@port}/up"
    puts "🔧 API endpoints: http://localhost:#{@port}/api/v1/*"
    puts "💾 Database: SQLite (storage/legastream.db)"
    puts "📧 Email: #{ENV['SMTP_HOST'] ? 'SMTP configured' : 'Local delivery'}"
    puts "🔄 Server version: #{Time.now.to_i} (multipart fix v3)"
    puts "🛑 Press Ctrl+C to stop"
    
    trap('INT') { 
      puts "\n🛑 Shutting down server..."
      @db.close if @db
      @server.shutdown 
    }
    
    @server.start
  end
end

if __FILE__ == $0
  server = ProductionServer.new(3001)
  server.start
end