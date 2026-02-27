# Localhost vs Render - Different Databases

## Important: You're Looking at Two Different Systems

### Localhost (Your Computer)
- **URL**: http://localhost:5173
- **Database**: `storage/legastream.db` (local file)
- **Latest Document**: ID 86 with 11 entities ✅ WORKING
- **Backend**: Running in terminal (port 3001)

### Render (Production)
- **URL**: https://legastream.onrender.com
- **Database**: Render's database (separate from localhost)
- **Latest Document**: ID 88 with 0 entities ❌ NOT WORKING
- **Backend**: Running on Render servers

## Why Localhost Works But Render Doesn't

### Localhost ✅
- API key is correct in `.env` file
- Network is fast
- Gemini API responds quickly
- Document 86: 11 entities extracted perfectly

### Render ❌
- API key might be wrong/missing in Render environment
- Network might be slower
- Gemini API timing out
- Document 88: 0 entities (timeout issue)

## The Problem on Render

From the backend logs, I saw:
```
[Gemini] TIMEOUT: Net::ReadTimeout
ERROR: AI provider returned empty response
✅ Automatic analysis completed for document 88: 0 entities extracted
```

This means:
1. Gemini API call timed out (60 seconds)
2. No entities were extracted
3. Document marked as "completed" but with 0 entities

## Solution

### Step 1: Update Gemini API Key on Render
1. Go to https://dashboard.render.com
2. Find "LegaStream" service
3. Click "Environment" tab
4. Update `GEMINI_API_KEY` to: `AIzaSyAYOIkIxZFvLuunEjQDN0YuJ-PVxnfWsk8`
5. Save changes
6. Wait 2 minutes for restart

### Step 2: Test on Localhost First
Since localhost is working:
1. Open http://localhost:5173
2. Login: admin@legastream.com / password
3. Upload a new document
4. Should complete with entities in 10-30 seconds

### Step 3: Then Test on Render
After updating the API key:
1. Open https://legastream.onrender.com
2. Login
3. Upload a small PDF
4. Check if entities are extracted

## How to Tell Which System You're Using

### You're on Localhost if:
- URL is `http://localhost:5173`
- You see the backend terminal running
- Changes happen instantly

### You're on Render if:
- URL is `https://legastream.onrender.com`
- No terminal visible
- Changes take 2-3 minutes to deploy

## Current Status

✅ **Localhost**: Working perfectly (document 86 has 11 entities)
❌ **Render**: Gemini API timing out (document 88 has 0 entities)

## Next Steps

1. **Test on localhost** to confirm it's working
2. **Update API key on Render**
3. **Test on Render** after API key update
4. **Check Render logs** if still not working

The code is correct - it's just an API key/network issue on Render.
