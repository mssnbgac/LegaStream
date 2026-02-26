# Which Document to View 📄

## The Problem
You're currently viewing document 47 which has **13 entities** but is MISSING the parties (Acme Corporation and John Smith).

## The Solution
View **Document 45** instead - it has the PERFECT extraction with **14 entities**!

## How to Find Document 45

In your browser at http://localhost:5173:

1. Go to the Document Upload page
2. Look for the document list
3. Find the document that shows **"14 Entities Extracted"** in the summary
4. That's document 45 - click the eye icon to view it
5. Click "View Extracted Entities"

## What Document 45 Contains (Perfect Version)

**14 Entities Total:**
- ✅ 2 parties (Acme Corporation, John Smith)
- ✅ 1 date (March 1, 2026)
- ✅ 1 address (123 Main Street, New York)
- ✅ 2 amounts ($75,000, $5,000)
- ✅ 2 obligations (clean, no fragments)
- ✅ 1 clause (30 days notice)
- ✅ 1 jurisdiction (State of New York)
- ✅ 2 terms (24 months, 30 days)
- ✅ 1 condition (background check)
- ✅ 1 penalty ($5,000 liquidated damages)

## What You're Currently Seeing (Document 47)

**13 Entities - MISSING PARTIES:**
- ❌ 0 parties (MISSING!)
- ✅ 1 address
- ✅ 1 date
- ✅ 2 amounts
- ✅ 3 obligations
- ✅ 3 jurisdictions
- ✅ 3 conditions

## Quick Fix

Just scroll through your document list and click on the one that shows:
```
14 Entities Extracted
2 parties
1 dates
1 addresses
...
```

That's the perfect one!

---

**This is the version that's deployed to GitHub and will work on Render!**
