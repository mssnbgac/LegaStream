# ⚠️ URGENT: Gemini API Key Has Been Leaked

## Problem
Your Gemini API key has been detected as leaked and has been disabled by Google for security reasons.

**Error message:**
```
Your API key was reported as leaked. Please use another API key.
```

## Why This Happened
API keys should NEVER be committed to public repositories or shared publicly. Your key was likely exposed in:
- Git commits
- Public GitHub repository
- Screenshots or documentation

## Solution: Generate a New API Key

### Step 1: Revoke the Old Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Find your leaked key: `AIzaSyCgDuGe3beNs2wVq-KXYhWHPJ0SAP8340g`
3. Click "Delete" or "Revoke" to permanently disable it

### Step 2: Create a New API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Select your Google Cloud project (or create a new one)
4. Copy the new API key immediately

### Step 3: Update Your .env File
1. Open `.env` file in your project
2. Replace the old key with your new key:
   ```
   GEMINI_API_KEY=your_new_api_key_here
   ```
3. Save the file

### Step 4: Secure Your API Key
1. **NEVER commit .env to Git** - it's already in `.gitignore`
2. **NEVER share your API key** in screenshots, messages, or documentation
3. **Use environment variables** in production (Render dashboard)

### Step 5: Update Render Environment Variables
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Select your LegaStream service
3. Go to "Environment" tab
4. Update `GEMINI_API_KEY` with your new key
5. Click "Save Changes"
6. Render will automatically redeploy

## After Getting New Key

Run this command to test the new key:
```powershell
ruby test_gemini_now.rb
```

You should see:
```
✅ Gemini API is working!
```

## Important Notes

1. **Free Tier Limits:**
   - 60 requests per minute
   - 1,500 requests per day
   - Sufficient for testing and small-scale use

2. **Available Models:**
   - `gemini-pro` - Best for text generation
   - `gemini-pro-vision` - For image + text
   - Check [Google AI Studio](https://makersuite.google.com) for latest models

3. **Security Best Practices:**
   - Keep `.env` in `.gitignore` ✓
   - Use environment variables in production ✓
   - Rotate keys regularly
   - Monitor usage in Google Cloud Console

## Need Help?

If you encounter any issues:
1. Verify the new key works: `ruby test_gemini_now.rb`
2. Check `.env` file has correct format (no quotes, no spaces)
3. Restart your server: `.\simple_restart.ps1`
4. Check Render logs for any errors

---

**Next Steps:**
1. Get new API key from Google AI Studio
2. Update `.env` file
3. Test locally
4. Update Render environment variables
5. Redeploy to production
