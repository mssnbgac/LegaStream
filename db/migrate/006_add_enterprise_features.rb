# Enterprise Features Migration
# Adds audit trail, verification workflow, and multi-document support

require 'sqlite3'

class AddEnterpriseFeatures
  def self.up
    db = SQLite3::Database.new('storage/legastream.db')
    
    # Audit trail for compliance
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        document_id INTEGER,
        action TEXT NOT NULL,
        resource_type TEXT,
        resource_id INTEGER,
        details TEXT,
        ip_address TEXT,
        user_agent TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (document_id) REFERENCES documents (id)
      )
    SQL
    
    # Entity verification for human-in-the-loop
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS entity_verifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_id INTEGER NOT NULL,
        verified_by_user_id INTEGER,
        status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'corrected'
        original_value TEXT,
        corrected_value TEXT,
        correction_reason TEXT,
        verified_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (entity_id) REFERENCES entities (id),
        FOREIGN KEY (verified_by_user_id) REFERENCES users (id)
      )
    SQL
    
    # Document relationships for multi-document analysis
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS document_relationships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_document_id INTEGER NOT NULL,
        child_document_id INTEGER NOT NULL,
        relationship_type TEXT NOT NULL, -- 'amendment', 'related', 'supersedes', 'referenced_by'
        description TEXT,
        created_by_user_id INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_document_id) REFERENCES documents (id) ON DELETE CASCADE,
        FOREIGN KEY (child_document_id) REFERENCES documents (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by_user_id) REFERENCES users (id)
      )
    SQL
    
    # AI analysis metadata for tracking
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS analysis_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        ai_provider TEXT NOT NULL, -- 'gemini', 'claude', 'gpt4', 'consensus'
        model_version TEXT,
        confidence_score REAL,
        processing_time_ms INTEGER,
        tokens_used INTEGER,
        cost_usd REAL,
        error_message TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    SQL
    
    # Document collections for portfolio analysis
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS document_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        collection_type TEXT, -- 'portfolio', 'case', 'project'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    SQL
    
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS collection_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        document_id INTEGER NOT NULL,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (collection_id) REFERENCES document_collections (id) ON DELETE CASCADE,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE,
        UNIQUE(collection_id, document_id)
      )
    SQL
    
    # Add enterprise fields to existing tables
    begin
      db.execute "ALTER TABLE entities ADD COLUMN requires_verification BOOLEAN DEFAULT 0"
      db.execute "ALTER TABLE entities ADD COLUMN verification_status TEXT DEFAULT 'unverified'"
      db.execute "ALTER TABLE entities ADD COLUMN metadata TEXT"
    rescue SQLite3::SQLException => e
      puts "Columns may already exist: #{e.message}"
    end
    
    begin
      db.execute "ALTER TABLE documents ADD COLUMN enterprise_analysis TEXT"
      db.execute "ALTER TABLE documents ADD COLUMN compliance_score INTEGER"
      db.execute "ALTER TABLE documents ADD COLUMN risk_level TEXT"
      db.execute "ALTER TABLE documents ADD COLUMN requires_review BOOLEAN DEFAULT 0"
    rescue SQLite3::SQLException => e
      puts "Columns may already exist: #{e.message}"
    end
    
    # Create indexes for performance
    db.execute "CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_audit_logs_document ON audit_logs(document_id)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_entity_verifications_status ON entity_verifications(status)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_analysis_metadata_document ON analysis_metadata(document_id)"
    
    puts "✅ Enterprise features migration completed successfully"
    db.close
  end
  
  def self.down
    db = SQLite3::Database.new('storage/legastream.db')
    
    db.execute "DROP TABLE IF EXISTS audit_logs"
    db.execute "DROP TABLE IF EXISTS entity_verifications"
    db.execute "DROP TABLE IF EXISTS document_relationships"
    db.execute "DROP TABLE IF EXISTS analysis_metadata"
    db.execute "DROP TABLE IF EXISTS collection_documents"
    db.execute "DROP TABLE IF EXISTS document_collections"
    
    puts "✅ Enterprise features migration rolled back"
    db.close
  end
end

# Run migration if executed directly
if __FILE__ == $0
  AddEnterpriseFeatures.up
end
