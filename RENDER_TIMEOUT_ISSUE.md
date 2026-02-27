# Render Timeout Issue - Document Stuck Processing

## Problem

Document uploaded 3+ minutes ago and still showing "processing" status on Render.

## Root Cause

The Gemini API is timing out on Render. This happens when:
1. **API key is wrong/missing** (most likely)
2. **API key has hit quota limits**
3. **Network timeout from Render servers**

## Solution

### Step 1: Update Gemini API Key on Render

1. Go to https://dashboard.render.com
2. Find your "LegaStream" service
3. Click "Environment" tab
4. Find or add `GEMINI_API_KEY`
5. Set value to: `AIzaSyAYOIkIxZFvLuunEjQDN0YuJ-PVxnfWsk8`
6. Click "Save Changes"
7. Render will restart the service (takes 1-2 minutes)

### Step 2: Check Render Logs

1. In Render Dashboard, click "Logs" tab
2. Look for errors like:
   - `403 Forbidden` - API key blocked/invalid
   - `429 Too Many Requests` - Quota exceeded
   - `Timeout` - Network timeout
   - `API key` - Key not found or wrong

### Step 3: Fix Stuck Document

The stuck document needs to be marked as error so you can retry:

**Option A: Via Render Shell**
1. Go to Render Dashboard → Shell tab
2. Run:
```ruby
require 'sqlite3'
db = SQLite3::Database.new('storage/legastream.db')
db.execute("UPDATE documents SET status = 'error' WHERE status = 'processing'")
db.close
puts "Fixed stuck documents"
```

**Option B: Delete and Re-upload**
1. Delete the stuck document from the UI
2. Upload it again after fixing the API key

## Why This Happens on Render but Not Localhost

- **Localhost**: Uses your local network, faster API responses
- **Render**: Cloud servers, sometimes slower network, stricter timeouts

## Gemini API Timeout Settings

The current timeout in `ai_provider.rb` is 60 seconds:
```ruby
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60)
```

If Gemini takes longer than 60 seconds, it times out and the document stays "processing".

## Quick Test

After updating the API key on Render:
1. Wait 2 minutes for Render to restart
2. Upload a small PDF (1-2 pages)
3. Should complete in 10-30 seconds
4. If still stuck, check Render logs

## Common Render Log Errors

### Error 1: API Key Not Set
```
[Gemini] ERROR: HTTP 403
Your API key was reported as leaked
```
**Fix**: Update GEMINI_API_KEY on Render

### Error 2: Timeout
```
[Gemini] TIMEOUT: execution expired
```
**Fix**: This is normal for large documents. Try smaller PDFs first.

### Error 3: Quota Exceeded
```
[Gemini] ERROR: HTTP 429
Resource has been exhausted
```
**Fix**: API key hit quota. Use a different key or wait 24 hours.

## Expected Processing Times

- Small PDF (1-5 pages): 10-30 seconds
- Medium PDF (5-20 pages): 30-90 seconds
- Large PDF (20+ pages): 90-180 seconds

If it takes longer than 3 minutes, something is wrong.

## Immediate Action

1. **Update GEMINI_API_KEY on Render** (most important)
2. **Check Render logs** for specific error
3. **Delete stuck document** and retry after fixing API key

The API key is the most likely issue since the code works perfectly on localhost.
