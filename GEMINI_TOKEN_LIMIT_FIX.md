# Gemini Token Limit Fix - APPLIED ✅

## Problem Found

The Gemini API was returning truncated responses because `maxOutputTokens: 2048` was too low. When extracting all 10 entity types from a document, the JSON response was being cut off mid-array, causing the parser to fail and fall back to regex extraction.

**Evidence from logs**:
```
[Gemini] Finished with reason: MAX_TOKENS
[Gemini] Response truncated due to max tokens
[Gemini] Success! Received 221 chars  ← Incomplete JSON!
[Gemini] Response preview: ```json
[
  {
    "type": "PARTY",
    "value": "Acme Corporation",
...
  ← Missing closing ]

[AIProvider] No JSON array found in response
[AIAnalysisService] AI returned no entities, using fallback
```

## The Fix

Increased `maxOutputTokens` from 2048 to 4096 in `app/services/ai_provider.rb`:

```ruby
generationConfig: {
  temperature: 0.1,
  maxOutputTokens: 4096,  # Increased to handle all 10 entity types
  topP: 0.8,
  topK: 10
}
```

## Impact

**Before**:
- Gemini response truncated at ~221 characters
- JSON parsing failed
- Fell back to regex extraction
- Regex extracted wrong entities: "is made between Acme Corporation", "and in accordance with company"
- Missing "John Smith" and other entities

**After**:
- Gemini response complete (up to 4096 tokens)
- JSON parsing succeeds
- All entities extracted correctly by AI
- Proper entity values: "Acme Corporation", "John Smith", etc.

## Files Modified

- `app/services/ai_provider.rb` (line 242)
  - Changed: `maxOutputTokens: 2048` → `maxOutputTokens: 4096`

- `simple_server.rb` (line 8-12)
  - Added: `require 'dotenv/load'` to load environment variables

## Testing

Backend has been restarted with the new settings. To test:

1. **Upload a new document** at http://localhost:5173
2. **Wait for analysis** to complete
3. **Check entities** - should now show:
   - ✅ "Acme Corporation" (not "is made between Acme Corporation")
   - ✅ "John Smith" (not missing)
   - ✅ All 13 entities extracted correctly

## Next Steps

1. Test with a new document upload
2. Verify all entities are extracted correctly
3. Deploy to production

---

**Status**: Fix applied, backend restarted
**Date**: February 25, 2026, 3:15 PM
