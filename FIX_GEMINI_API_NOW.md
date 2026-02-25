# 🔧 Fix Gemini API Integration - Action Required

## Current Status

❌ **Gemini API key has been leaked and disabled by Google**
❌ **Entity extraction is using fallback regex (incomplete results)**
✅ **Code has been fixed to use correct model name (`gemini-pro`)**

## What You're Seeing Now

**Incomplete entity extraction:**
- Missing penalties ($5,000 liquidated damages)
- Wrong jurisdiction extractions
- Missing clauses, terms, and conditions
- Only 7 entities instead of complete extraction

**Why:** The system is falling back to regex patterns because the Gemini API key is disabled.

## Required Actions

### 1. Get a New Gemini API Key (5 minutes)

1. **Go to Google AI Studio:**
   - Visit: https://makersuite.google.com/app/apikey
   - Sign in with your Google account

2. **Delete the leaked key:**
   - Find key: `AIzaSyCgDuGe3beNs2wVq-KXYhWHPJ0SAP8340g`
   - Click "Delete" to revoke it

3. **Create a new API key:**
   - Click "Create API Key"
   - Select your Google Cloud project (or create new)
   - Copy the new key immediately
   - **IMPORTANT:** Keep it secret!

### 2. Update Local Environment

1. **Open `.env` file** in your project

2. **Replace the old key:**
   ```env
   GEMINI_API_KEY=your_new_api_key_here
   ```
   
   Replace `your_new_api_key_here` with your actual new key

3. **Save the file**

### 3. Test the New Key

Run this command:
```powershell
ruby test_gemini_now.rb
```

**Expected output:**
```
✅ Gemini API is working!
```

**If you see an error:**
- Check the key is copied correctly (no spaces, no quotes)
- Verify the key is enabled in Google AI Studio
- Wait 1-2 minutes for the key to activate

### 4. Restart Your Server

```powershell
.\simple_restart.ps1
```

### 5. Test Entity Extraction

1. **Upload a new document** or re-upload an existing one
2. **Check the extracted entities** - you should now see:
   - ✓ All 10 entity types properly extracted
   - ✓ Penalties and damages detected
   - ✓ Accurate jurisdiction information
   - ✓ Complete clauses and terms
   - ✓ Higher confidence scores (90-95%)

### 6. Deploy to Render Production

Once local testing works:

1. **Commit changes:**
   ```powershell
   .\deploy_to_render.ps1
   ```

2. **Update Render environment variables:**
   - Go to: https://dashboard.render.com
   - Select your LegaStream service
   - Click "Environment" tab
   - Find `GEMINI_API_KEY`
   - Update with your new key
   - Click "Save Changes"

3. **Wait for automatic redeployment** (5-10 minutes)

4. **Test production:**
   - Visit: https://legastream.onrender.com
   - Upload a document
   - Verify AI extraction is working

## What Was Fixed in the Code

1. ✅ **Model name corrected:** `gemini-1.5-flash` → `gemini-pro`
2. ✅ **API version verified:** Using `v1beta` (required for Gemini)
3. ✅ **Duplicate entity prevention:** Fixed normalization logic
4. ✅ **Fallback extraction:** Removed unreliable person name extraction
5. ✅ **Entity display:** Shows all 10 types with descriptions

## Expected Results After Fix

### Before (Fallback Regex):
```
7 entities found
- Missing penalties
- Wrong jurisdictions
- Incomplete data
- Low accuracy
```

### After (Gemini AI):
```
15-25 entities found
✓ All penalties detected ($5,000 liquidated damages)
✓ Accurate jurisdictions (New York law)
✓ Complete clauses (termination, confidentiality)
✓ All terms and conditions
✓ High confidence (90-95%)
```

## Security Best Practices

### ✅ DO:
- Keep API keys in `.env` file (already in `.gitignore`)
- Use environment variables in production
- Rotate keys regularly
- Monitor usage in Google Cloud Console

### ❌ DON'T:
- Commit `.env` to Git
- Share API keys in screenshots
- Post keys in documentation
- Use keys in client-side code

## Troubleshooting

### "API key not working"
- Wait 1-2 minutes after creating the key
- Check for typos in `.env` file
- Verify key is enabled in Google AI Studio

### "Still seeing fallback extraction"
- Restart the server: `.\simple_restart.ps1`
- Check server logs for Gemini API errors
- Verify `.env` file is in the correct location

### "Render deployment not working"
- Verify environment variable is saved in Render dashboard
- Check Render logs for errors
- Wait for full redeployment (5-10 minutes)

## Free Tier Limits

**Gemini API Free Tier:**
- 60 requests per minute
- 1,500 requests per day
- Sufficient for testing and demos

**If you exceed limits:**
- Upgrade to paid tier in Google Cloud Console
- Or implement rate limiting in your app

## Next Steps

1. ✅ Get new Gemini API key
2. ✅ Update `.env` file
3. ✅ Test locally: `ruby test_gemini_now.rb`
4. ✅ Restart server: `.\simple_restart.ps1`
5. ✅ Upload test document
6. ✅ Verify AI extraction works
7. ✅ Deploy to Render
8. ✅ Update Render environment variables
9. ✅ Test production

---

**Need Help?**
- Check `GEMINI_API_KEY_LEAKED.md` for detailed security info
- Run `ruby test_gemini_now.rb` to test API connectivity
- Check server logs for detailed error messages
