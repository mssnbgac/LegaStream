import React, { useState, useEffect } from 'react'
import { 
  Upload, 
  FileText, 
  X, 
  CheckCircle, 
  AlertCircle, 
  Clock,
  Eye,
  Download,
  Trash2,
  Play,
  Brain,
  Shield,
  Zap,
  RefreshCw
} from 'lucide-react'
import { authenticatedFetch } from '../utils/auth'

export function DocumentUpload() {
  const [dragActive, setDragActive] = useState(false)
  const [files, setFiles] = useState([])
  const [uploading, setUploading] = useState(false)
  const [documents, setDocuments] = useState([])
  const [selectedDocument, setSelectedDocument] = useState(null)
  const [entities, setEntities] = useState(null)
  const [showEntities, setShowEntities] = useState(false)
  const [refreshing, setRefreshing] = useState(false)

  // Fetch existing documents on component mount
  useEffect(() => {
    fetchDocuments()
  }, [])

  const fetchDocuments = async () => {
    try {
      setRefreshing(true)
      const response = await authenticatedFetch('/api/v1/documents')
      if (response) {
        const data = await response.json()
        setDocuments(data.documents || [])
      }
    } catch (error) {
      console.error('Failed to fetch documents:', error)
    } finally {
      setRefreshing(false)
    }
  }

  const handleDrag = (e) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true)
    } else if (e.type === 'dragleave') {
      setDragActive(false)
    }
  }

  const handleDrop = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFiles(e.dataTransfer.files)
    }
  }

  const handleChange = (e) => {
    e.preventDefault()
    if (e.target.files && e.target.files[0]) {
      handleFiles(e.target.files)
    }
  }

  const handleFiles = (fileList) => {
    const newFiles = Array.from(fileList).map(file => ({
      id: Math.random().toString(36).substr(2, 9),
      file,
      name: file.name,
      size: file.size,
      type: file.type,
      status: 'pending',
      progress: 0
    }))
    
    setFiles(prev => [...prev, ...newFiles])
  }

  const removeFile = (id) => {
    setFiles(prev => prev.filter(file => file.id !== id))
  }

  const uploadFiles = async () => {
    setUploading(true)
    
    for (let file of files.filter(f => f.status === 'pending')) {
      try {
        // Update status to uploading
        setFiles(prev => prev.map(f => 
          f.id === file.id ? { ...f, status: 'uploading' } : f
        ))

        // Create FormData to send actual file
        const formData = new FormData()
        formData.append('file', file.file)
        formData.append('filename', file.name)
        formData.append('size', file.size)
        formData.append('type', file.type)

        // Upload with progress tracking
        const xhr = new XMLHttpRequest()
        
        // Track upload progress
        xhr.upload.addEventListener('progress', (e) => {
          if (e.lengthComputable) {
            const progress = Math.round((e.loaded / e.total) * 100)
            setFiles(prev => prev.map(f => 
              f.id === file.id ? { ...f, progress } : f
            ))
          }
        })

        // Handle completion
        const uploadPromise = new Promise((resolve, reject) => {
          xhr.addEventListener('load', () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              resolve(JSON.parse(xhr.responseText))
            } else {
              reject(new Error(`Upload failed: ${xhr.status}`))
            }
          })
          xhr.addEventListener('error', () => reject(new Error('Upload failed')))
        })

        // Get auth token
        const token = localStorage.getItem('authToken')
        
        // Send request
        xhr.open('POST', '/api/v1/documents')
        xhr.setRequestHeader('Authorization', `Bearer ${token}`)
        xhr.send(formData)

        await uploadPromise

        // Mark as completed
        setFiles(prev => prev.map(f => 
          f.id === file.id ? { ...f, status: 'completed', progress: 100 } : f
        ))
      } catch (error) {
        console.error('Upload error:', error)
        setFiles(prev => prev.map(f => 
          f.id === file.id ? { ...f, status: 'error', progress: 0 } : f
        ))
      }
    }
    
    setUploading(false)
    // Refresh documents list
    setTimeout(fetchDocuments, 1000)
  }

  const analyzeDocument = async (docId) => {
    try {
      const response = await authenticatedFetch(`/api/v1/documents/${docId}/analyze`, {
        method: 'POST'
      })
      
      if (response && response.ok) {
        // Refresh documents to show updated status
        setTimeout(fetchDocuments, 1000)
      }
    } catch (error) {
      console.error('Analysis error:', error)
    }
  }

  const deleteDocument = async (docId) => {
    if (!confirm('Are you sure you want to delete this document?')) {
      return
    }
    
    try {
      const response = await authenticatedFetch(`/api/v1/documents/${docId}`, {
        method: 'DELETE'
      })
      
      if (response && response.ok) {
        // Immediately update UI by removing the document from state
        setDocuments(prev => prev.filter(doc => doc.id !== docId))
        console.log('Document deleted successfully')
      } else {
        const errorData = await response.json().catch(() => ({}))
        console.error('Delete failed:', response.status, errorData)
        alert(`Failed to delete document: ${errorData.error || 'Unknown error'}`)
      }
    } catch (error) {
      console.error('Delete error:', error)
      alert('Failed to delete document. Please try again.')
    }
  }

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString()
  }

  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-5 w-5 text-green-500" />
      case 'processing':
        return <div className="h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      case 'error':
        return <AlertCircle className="h-5 w-5 text-red-500" />
      case 'uploading':
        return <div className="h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      default:
        return <FileText className="h-5 w-5 text-gray-400" />
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'text-green-400 bg-green-900/50 border border-green-800'
      case 'processing': return 'text-blue-400 bg-blue-900/50 border border-blue-800'
      case 'error': return 'text-red-400 bg-red-900/50 border border-red-800'
      case 'uploaded': return 'text-amber-400 bg-amber-900/50 border border-amber-800'
      default: return 'text-gray-400 bg-gray-700 border border-gray-600'
    }
  }

  return (
    <div className="w-full max-w-7xl mx-auto space-y-8">
      {/* Header - Centered */}
      <div className="text-center lg:text-left">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div className="mb-6 lg:mb-0">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-3">Document Processing</h1>
            <p className="text-xl text-gray-600 dark:text-gray-400">
              Upload and analyze legal documents with AI-powered insights
            </p>
          </div>
          <div className="flex items-center justify-center lg:justify-end space-x-3">
            <div className="flex items-center space-x-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-400 rounded-xl text-sm font-medium border border-blue-300 dark:border-blue-800">
              <Brain className="h-4 w-4" />
              <span>AI Analysis Ready</span>
            </div>
          </div>
        </div>
      </div>

      {/* Upload Area - Centered with max width */}
      <div className="max-w-4xl mx-auto">
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-8 shadow-sm">
          <div
            className={`relative border-2 border-dashed rounded-2xl p-12 text-center transition-all duration-200 ${
              dragActive
                ? 'border-blue-500 bg-blue-100 dark:bg-blue-900/20 scale-105'
                : 'border-gray-400 dark:border-gray-600 hover:border-gray-500 dark:hover:border-gray-500 hover:bg-gray-50 dark:hover:bg-gray-700/50'
            }`}
            onDragEnter={handleDrag}
            onDragLeave={handleDrag}
            onDragOver={handleDrag}
            onDrop={handleDrop}
          >
            <div className="flex flex-col items-center space-y-6">
              <div className="p-6 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl shadow-lg">
                <Upload className="h-12 w-12 text-white" />
              </div>
              <div>
                <label htmlFor="file-upload" className="cursor-pointer">
                  <span className="text-2xl font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors">
                    Upload Legal Documents
                  </span>
                  <input
                    id="file-upload"
                    name="file-upload"
                    type="file"
                    className="sr-only"
                    multiple
                    accept=".pdf,.docx,.txt"
                    onChange={handleChange}
                  />
                </label>
                <p className="text-gray-600 dark:text-gray-400 mt-3 text-lg">or drag and drop files here</p>
              </div>
              <div className="flex items-center justify-center space-x-8 text-base text-gray-600 dark:text-gray-400">
                <div className="flex items-center space-x-2">
                  <Shield className="h-5 w-5" />
                  <span>Secure Processing</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Zap className="h-5 w-5" />
                  <span>AI-Powered Analysis</span>
                </div>
              </div>
              <p className="text-base text-gray-500 dark:text-gray-500">
                Supports PDF, DOCX, TXT • Up to 100MB per file • 500+ pages supported
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* File Upload Queue - Centered */}
      {files.length > 0 && (
        <div className="max-w-5xl mx-auto">
          <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm">
            <div className="px-6 py-5 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                Upload Queue ({files.length})
              </h2>
              {files.some(f => f.status === 'pending') && (
                <button
                  onClick={uploadFiles}
                  disabled={uploading}
                  className="px-6 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl font-medium hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-lg shadow-blue-500/25"
                >
                  {uploading ? 'Uploading...' : 'Upload All'}
                </button>
              )}
            </div>
            
            <div className="divide-y divide-gray-200 dark:divide-gray-700">
              {files.map((file) => (
                <div key={file.id} className="px-6 py-5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4 flex-1">
                      {getStatusIcon(file.status)}
                      <div className="flex-1 min-w-0">
                        <p className="text-base font-medium text-gray-900 dark:text-white truncate">
                          {file.name}
                        </p>
                        <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                          {formatFileSize(file.size)} • {file.type}
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-4">
                      {file.status === 'uploading' && (
                        <div className="w-40">
                          <div className="bg-gray-300 dark:bg-gray-600 rounded-full h-3">
                            <div
                              className="bg-gradient-to-r from-blue-500 to-indigo-600 h-3 rounded-full transition-all duration-300"
                              style={{ width: `${file.progress}%` }}
                            />
                          </div>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-2 text-center">
                            {file.progress}%
                          </p>
                        </div>
                      )}
                      
                      {file.status === 'completed' && (
                        <span className="text-base text-green-600 dark:text-green-400 font-medium">
                          Uploaded Successfully
                        </span>
                      )}
                      
                      {file.status === 'error' && (
                        <span className="text-base text-red-600 dark:text-red-400 font-medium">
                          Upload Failed
                        </span>
                      )}
                      
                      <button
                        onClick={() => removeFile(file.id)}
                        className="text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors p-2"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Documents List - Centered */}
      <div className="max-w-6xl mx-auto">
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm">
          <div className="px-6 py-5 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              Processed Documents ({documents.length})
            </h2>
            <button
              onClick={fetchDocuments}
              disabled={refreshing}
              className="px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-xl font-medium hover:bg-gray-300 dark:hover:bg-gray-600 hover:text-gray-900 dark:hover:text-white transition-all duration-200 border border-gray-300 dark:border-gray-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
            >
              <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
              <span>{refreshing ? 'Refreshing...' : 'Refresh'}</span>
            </button>
          </div>
          
          {documents.length === 0 ? (
            <div className="p-16 text-center">
              <FileText className="h-16 w-16 text-gray-400 dark:text-gray-600 mx-auto mb-6" />
              <p className="text-xl text-gray-700 dark:text-gray-400 mb-2">No documents uploaded yet</p>
              <p className="text-base text-gray-500 dark:text-gray-500">Upload your first document to get started</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-200 dark:divide-gray-700">
              {documents.map((doc) => (
                <div key={doc.id} className="px-6 py-5 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4 flex-1">
                      {getStatusIcon(doc.status)}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3 mb-2">
                          <p className="text-base font-medium text-gray-900 dark:text-white truncate">
                            {doc.original_filename || doc.filename}
                          </p>
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(doc.status)}`}>
                            {doc.status}
                          </span>
                        </div>
                        <div className="flex items-center space-x-4 text-sm text-gray-600 dark:text-gray-400">
                          <span>{formatFileSize(doc.file_size)}</span>
                          <span>•</span>
                          <span>{formatDate(doc.created_at)}</span>
                          {doc.analysis_results && (
                            <>
                              <span>•</span>
                              <span className="text-green-600 dark:text-green-400">
                                {doc.analysis_results?.entities_extracted || 0} entities found
                              </span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      {doc.status === 'completed' && (
                        <button
                          onClick={() => setSelectedDocument(doc)}
                          className="p-3 text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/50 transition-colors"
                          title="View Analysis"
                        >
                          <Eye className="h-5 w-5" />
                        </button>
                      )}
                      
                      {doc.status === 'uploaded' && (
                        <button
                          onClick={() => analyzeDocument(doc.id)}
                          className="p-3 text-gray-600 dark:text-gray-400 hover:text-green-600 dark:hover:text-green-400 rounded-lg hover:bg-green-100 dark:hover:bg-green-900/50 transition-colors"
                          title="Start Analysis"
                        >
                          <Play className="h-5 w-5" />
                        </button>
                      )}
                      
                      <button
                        onClick={() => deleteDocument(doc.id)}
                        className="p-3 text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/50 transition-colors"
                        title="Delete Document"
                      >
                        <Trash2 className="h-5 w-5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Document Analysis Modal - Enhanced */}
      {selectedDocument && selectedDocument.analysis_results && (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-2xl max-w-6xl w-full max-h-[90vh] overflow-y-auto border border-gray-200 dark:border-gray-700 shadow-2xl">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between sticky top-0 bg-white dark:bg-gray-800 z-10">
              <div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                  AI Analysis Results
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {selectedDocument.original_filename}
                </p>
              </div>
              <button
                onClick={() => setSelectedDocument(null)}
                className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                <X className="h-6 w-6" />
              </button>
            </div>
            
            <div className="p-6 space-y-8">
              {/* Top Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/50 dark:to-blue-800/50 rounded-xl p-5 border border-blue-200 dark:border-blue-700">
                  <div className="text-3xl font-bold text-blue-600 dark:text-blue-400">
                    {selectedDocument.analysis_results?.entities_extracted || 0}
                  </div>
                  <div className="text-sm text-blue-700 dark:text-blue-300 mt-1">Entities Extracted</div>
                </div>
                <div className="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/50 dark:to-green-800/50 rounded-xl p-5 border border-green-200 dark:border-green-700">
                  <div className="text-3xl font-bold text-green-600 dark:text-green-400">
                    {selectedDocument.analysis_results?.compliance_score?.toFixed?.(0) || 'N/A'}%
                  </div>
                  <div className="text-sm text-green-700 dark:text-green-300 mt-1">Compliance Score</div>
                </div>
                <div className="bg-gradient-to-br from-purple-50 to-purple-100 dark:from-purple-900/50 dark:to-purple-800/50 rounded-xl p-5 border border-purple-200 dark:border-purple-700">
                  <div className="text-3xl font-bold text-purple-600 dark:text-purple-400">
                    {selectedDocument.analysis_results?.confidence_score?.toFixed?.(0) || selectedDocument.analysis_results?.completeness?.score || 'N/A'}%
                  </div>
                  <div className="text-sm text-purple-700 dark:text-purple-300 mt-1">AI Confidence</div>
                </div>
                <div className="bg-gradient-to-br from-amber-50 to-amber-100 dark:from-amber-900/50 dark:to-amber-800/50 rounded-xl p-5 border border-amber-200 dark:border-amber-700">
                  <div className="text-3xl font-bold text-amber-600 dark:text-amber-400 capitalize">
                    {selectedDocument.analysis_results?.risk_level?.level || selectedDocument.analysis_results?.risk_level || 'N/A'}
                  </div>
                  <div className="text-sm text-amber-700 dark:text-amber-300 mt-1">Risk Level</div>
                </div>
              </div>

              {/* AI Summary */}
              {selectedDocument.analysis_results.summary && (
                <div className="bg-gradient-to-r from-indigo-50 to-purple-50 dark:from-indigo-900/30 dark:to-purple-900/30 rounded-xl p-6 border border-indigo-200 dark:border-indigo-800">
                  <div className="flex items-start space-x-3">
                    <Brain className="h-6 w-6 text-indigo-600 dark:text-indigo-400 flex-shrink-0 mt-1" />
                    <div>
                      <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">AI Summary</h4>
                      <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                        {selectedDocument.analysis_results.summary}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* Key Findings */}
              {selectedDocument.analysis_results.key_findings && selectedDocument.analysis_results.key_findings.length > 0 && (
                <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
                  <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                    <CheckCircle className="h-5 w-5 text-green-600 dark:text-green-400 mr-2" />
                    Key Findings
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {selectedDocument.analysis_results.key_findings.map((finding, index) => (
                      <div key={index} className="flex items-start space-x-3 bg-green-50 dark:bg-green-900/20 rounded-lg p-3 border border-green-200 dark:border-green-800">
                        <CheckCircle className="h-4 w-4 text-green-600 dark:text-green-400 flex-shrink-0 mt-0.5" />
                        <span className="text-sm text-gray-700 dark:text-gray-300">{finding}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Risk Assessment Details */}
              {selectedDocument.analysis_results.risk_assessment && (
                <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
                  <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                    <Shield className="h-5 w-5 text-amber-600 dark:text-amber-400 mr-2" />
                    Risk Assessment by Category
                  </h4>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {Object.entries(selectedDocument.analysis_results.risk_assessment).map(([key, value]) => (
                      <div key={key} className={`rounded-lg p-4 border text-center ${
                        value === 'Low' 
                          ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800' 
                          : value === 'Medium'
                          ? 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800'
                          : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
                      }`}>
                        <div className={`text-2xl font-bold mb-1 ${
                          value === 'Low' ? 'text-green-600 dark:text-green-400' :
                          value === 'Medium' ? 'text-amber-600 dark:text-amber-400' :
                          'text-red-600 dark:text-red-400'
                        }`}>
                          {value}
                        </div>
                        <div className="text-xs text-gray-600 dark:text-gray-400 capitalize font-medium">
                          {key.replace(/_/g, ' ')}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* View Entities Button */}
              <div className="flex justify-center">
                <button
                  onClick={async () => {
                    try {
                      const response = await authenticatedFetch(`/api/v1/documents/${selectedDocument.id}/entities`)
                      if (response && response.ok) {
                        const data = await response.json()
                        setEntities(data)
                        setShowEntities(true)
                      } else {
                        alert('Failed to fetch entities. Please try again.')
                      }
                    } catch (error) {
                      console.error('Failed to fetch entities:', error)
                      alert('Error fetching entities. Please check the console.')
                    }
                  }}
                  className="px-6 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl font-medium hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-lg shadow-blue-500/25 flex items-center space-x-2"
                >
                  <Eye className="h-5 w-5" />
                  <span>View Extracted Entities</span>
                </button>
              </div>

              {/* Additional Info */}
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                  <div>
                    <span className="text-gray-600 dark:text-gray-400">Issues Flagged:</span>
                    <span className="ml-2 font-semibold text-gray-900 dark:text-white">
                      {selectedDocument.analysis_results?.issues_flagged || selectedDocument.analysis_results?.risk_level?.count || 0}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600 dark:text-gray-400">Document Status:</span>
                    <span className="ml-2 font-semibold text-gray-900 dark:text-white capitalize">
                      {selectedDocument.status}
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-600 dark:text-gray-400">Analyzed:</span>
                    <span className="ml-2 font-semibold text-gray-900 dark:text-white">
                      {formatDate(selectedDocument.updated_at)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Success Message */}
      {files.some(f => f.status === 'completed') && (
        <div className="bg-gradient-to-r from-green-100 to-emerald-100 dark:from-green-900/50 dark:to-emerald-900/50 border border-green-300 dark:border-green-800 rounded-2xl p-6">
          <div className="flex items-center space-x-3">
            <div className="flex-shrink-0">
              <CheckCircle className="h-6 w-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-green-800 dark:text-green-300">
                Documents uploaded successfully!
              </h3>
              <p className="text-green-700 dark:text-green-400 mt-1">
                Your documents are being processed by our AI engine. 
                Check the Live Terminal to see the analysis progress in real-time.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Entities Modal */}
      {showEntities && entities && (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-2xl max-w-5xl w-full max-h-[90vh] overflow-y-auto border border-gray-200 dark:border-gray-700 shadow-2xl">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between sticky top-0 bg-white dark:bg-gray-800 z-10">
              <div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                  Extracted Entities
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {entities.total_entities} entities found
                </p>
              </div>
              <button
                onClick={() => {
                  setShowEntities(false)
                  setEntities(null)
                }}
                className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            {/* Entity Summary */}
            <div className="p-6 space-y-6">
              {/* Entity List */}
              {entities.entities && entities.entities.length > 0 ? (
                <div className="space-y-4">
                  {/* Define all 10 entity types in order */}
                  {[
                    { type: 'PARTY', icon: '👥', label: 'Parties', description: 'People or organizations involved' },
                    { type: 'ADDRESS', icon: '📍', label: 'Addresses', description: 'Physical locations' },
                    { type: 'DATE', icon: '📅', label: 'Dates', description: 'Important dates and deadlines' },
                    { type: 'AMOUNT', icon: '💰', label: 'Amounts', description: 'Monetary values and compensation' },
                    { type: 'OBLIGATION', icon: '📋', label: 'Obligations', description: 'Legal duties and responsibilities' },
                    { type: 'CLAUSE', icon: '📄', label: 'Clauses', description: 'Contract terms and provisions' },
                    { type: 'JURISDICTION', icon: '⚖️', label: 'Jurisdictions', description: 'Governing laws and regulations' },
                    { type: 'TERM', icon: '⏱️', label: 'Terms', description: 'Duration and time periods' },
                    { type: 'CONDITION', icon: '✓', label: 'Conditions', description: 'Requirements and prerequisites' },
                    { type: 'PENALTY', icon: '⚠️', label: 'Penalties', description: 'Damages, fines, and consequences' }
                  ].map((entityDef, index) => {
                    // Get entities for this type
                    const typeEntities = entities.entities.filter(e => e.entity_type === entityDef.type);
                    
                    return (
                      <div key={entityDef.type} className="bg-gray-50 dark:bg-gray-900 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                        <div className="mb-3">
                          <h4 className="text-lg font-bold text-gray-900 dark:text-white flex items-center">
                            <span className="text-2xl mr-3">{entityDef.icon}</span>
                            <span className="mr-2">{index + 1}.</span>
                            {entityDef.label}
                            {typeEntities.length > 0 && (
                              <span className="ml-2 text-sm font-normal text-gray-600 dark:text-gray-400">
                                ({typeEntities.length} found)
                              </span>
                            )}
                          </h4>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1 ml-11">
                            {entityDef.description}
                          </p>
                        </div>
                        
                        {typeEntities.length > 0 ? (
                          <div className="ml-11 space-y-2">
                            {typeEntities.map((entity, idx) => (
                              <div key={idx} className="bg-white dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
                                <div className="flex items-start justify-between">
                                  <div className="flex-1">
                                    <div className="font-medium text-gray-900 dark:text-white">
                                      {entity.entity_value}
                                    </div>
                                    {entity.context && (
                                      <div className="text-sm text-gray-600 dark:text-gray-400 mt-1 italic">
                                        "{entity.context}"
                                      </div>
                                    )}
                                  </div>
                                  {entity.confidence && (
                                    <div className="ml-3 flex-shrink-0">
                                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                                        entity.confidence >= 0.9 
                                          ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 border border-green-200 dark:border-green-800'
                                          : entity.confidence >= 0.7
                                          ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-800'
                                          : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-400 border border-gray-200 dark:border-gray-600'
                                      }`}>
                                        {(entity.confidence * 100).toFixed(0)}% confidence
                                      </span>
                                    </div>
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <div className="ml-11 text-sm text-gray-500 dark:text-gray-500 italic">
                            No {entityDef.label.toLowerCase()} found in this document
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="text-center py-12">
                  <FileText className="h-16 w-16 text-gray-400 dark:text-gray-600 mx-auto mb-4" />
                  <p className="text-gray-600 dark:text-gray-400">No entities found in this document.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}