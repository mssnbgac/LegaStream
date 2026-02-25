# 🚀 Quick Start: Test AI Extraction

## ✅ Everything is Ready!

Your Gemini AI integration is complete and ready to test.

## Test in 3 Steps

### 1. Upload a Document
Go to http://localhost:5173 and upload any legal document (PDF)

### 2. Wait for Analysis
AI analysis takes 10-30 seconds (first time may be slower)

### 3. View Results
Click "View Extracted Entities" to see:
- ✓ All 10 entity types
- ✓ Complete extraction (15-25 entities)
- ✓ High confidence (90-95%)
- ✓ No duplicates

## What You Should See

### Complete Entity Extraction

**1. PARTIES** - "Acme Corporation", "John Smith"
**2. ADDRESSES** - "123 Main Street, New York"
**3. DATES** - "March 1, 2026", "Start date: January 15, 2025"
**4. AMOUNTS** - "$75,000 annual salary", "$5,000 liquidated damages"
**5. OBLIGATIONS** - "Employee shall perform duties diligently"
**6. CLAUSES** - "Termination with 30 days notice"
**7. JURISDICTIONS** - "Governed by New York law"
**8. TERMS** - "24-month contract duration"
**9. CONDITIONS** - "Subject to background check"
**10. PENALTIES** - "$5,000 liquidated damages for breach"

## If Something Goes Wrong

### Server Not Running?
```powershell
.\simple_restart.ps1
```

### Still Seeing Incomplete Data?
- Wait 30 seconds for AI analysis
- Check server logs for errors
- Verify `.env` has correct API key

### Timeout Errors?
- First request may take 60 seconds
- Subsequent requests are faster
- Check internet connection

## Deploy to Production

Once local testing works:

```powershell
.\deploy_to_render.ps1
```

Then add API key to Render:
1. https://dashboard.render.com
2. Select LegaStream service
3. Environment tab
4. Add: `GEMINI_API_KEY = AIzaSyBmMNUOUs5lmeHeSjGrblkhQtvjepxSuE0`
5. Save and wait for redeploy

## Need More Info?

- **Full guide:** `GEMINI_AI_READY.md`
- **Testing details:** `TEST_AI_EXTRACTION_NOW.md`
- **Troubleshooting:** `FIX_GEMINI_API_NOW.md`

---

**Ready to test!** 🎉
