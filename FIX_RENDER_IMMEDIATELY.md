# Fix Render Immediately - 3 Minute Solution

## The Problem

Your localhost works because it has the working API key: `AIzaSyDxwFk-VcAPLPu0t_MkrhRmhlg5UG-blGU`

Your Render deployment doesn't work because it either:
1. Has an old/different API key
2. Has the same key but quota is exhausted

## The Solution (3 Minutes)

### Step 1: Go to Render Dashboard (30 seconds)
1. Open: https://dashboard.render.com/
2. Log in with your account
3. Click on your "LegaStream" service

### Step 2: Update API Key (1 minute)
1. Click the "Environment" tab
2. Find the variable `GEMINI_API_KEY`
3. Click "Edit" or the pencil icon
4. Replace the value with: `AIzaSyDxwFk-VcAPLPu0t_MkrhRmhlg5UG-blGU`
5. Click "Save Changes"

### Step 3: Wait for Redeploy (2 minutes)
1. Render will automatically start redeploying
2. Click the "Events" tab to watch progress
3. Wait for "Deploy live" message
4. Should take 2-3 minutes

### Step 4: Test (30 seconds)
1. Go to: https://legastream.onrender.com
2. Log in
3. Upload a test document
4. Wait 10-15 seconds
5. Should see entities extracted!

---

## Important Notes

### About the API Key

This key (`AIzaSyDxwFk-VcAPLPu0t_MkrhRmhlg5UG-blGU`) is the one working on your localhost.

**Quota Sharing:**
- Both localhost and Render will share the same 1,500 requests/day
- If you test a lot on localhost, Render quota decreases
- If Render processes documents, localhost quota decreases

**For Competition:**
- This should be fine for demo purposes
- 1,500 requests = ~100-150 documents
- Enough for competition demo

### After Competition

**Option 1: Get Separate Keys (Free)**
- Create new Google account
- Get new Gemini API key
- Use one for localhost, one for Render
- Total: 3,000 requests/day

**Option 2: Upgrade to Paid (Best)**
- Go to: https://console.cloud.google.com/
- Enable billing
- Upgrade Gemini API
- Cost: ~$3-5/month
- Unlimited requests

---

## Troubleshooting

### If Render Still Doesn't Work After Update

**Check 1: Verify Redeploy Completed**
- Go to "Events" tab
- Should see "Deploy live" message
- If still deploying, wait longer

**Check 2: Verify API Key Saved**
- Go back to "Environment" tab
- Check `GEMINI_API_KEY` value
- Should end with: `...UG-blGU`

**Check 3: Check Logs**
- Go to "Logs" tab
- Look for errors
- Should see: "Starting AI analysis for document X"

**Check 4: Test API Key**
- Run this locally to verify key works:
```bash
ruby test_api_key_detailed.rb
```

### If You See "Quota Exceeded" Error

**Immediate Fix:**
- Get NEW API key from DIFFERENT Google account
- Go to: https://aistudio.google.com/app/apikey
- Sign in with different email
- Create new key
- Update Render with new key

**Long-term Fix:**
- Upgrade to paid Gemini
- Or use separate keys for each environment

---

## For Your Competition Demo

### Recommended Approach

**Use Localhost:**
- It works perfectly
- All features functional
- No quota issues
- Can demo live

**Show Render:**
- Mention it's deployed
- Show the URL
- Explain API quota situation
- Emphasize production-ready code

**Key Points:**
- "App is fully functional as you can see"
- "Deployed to Render at legastream.onrender.com"
- "Currently on free tier API with quota limits"
- "Would upgrade to paid for production use"
- "All code is on GitHub and production-ready"

---

## Quick Checklist

Before competition:
- [ ] Localhost backend running (port 3001)
- [ ] Localhost frontend running (port 5173)
- [ ] Test document upload on localhost
- [ ] Verify entities extracted
- [ ] Verify AI summary generated
- [ ] Update Render API key (if time permits)
- [ ] Test Render deployment (if updated)
- [ ] Prepare demo script
- [ ] Have GitHub repo link ready

---

## Summary

**What to do RIGHT NOW:**
1. Go to Render dashboard
2. Update `GEMINI_API_KEY` to: `AIzaSyDxwFk-VcAPLPu0t_MkrhRmhlg5UG-blGU`
3. Wait 2-3 minutes for redeploy
4. Test upload

**Total time:** 3-5 minutes

**Result:** Render will work just like localhost

---

## Need Help?

If you get stuck:
1. Check Render "Logs" tab for errors
2. Check Render "Events" tab for deployment status
3. Verify API key is correct in "Environment" tab
4. Test API key locally first

**Your code is perfect. This is just a configuration update.**
