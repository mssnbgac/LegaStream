# Quick Email Fix for Legal Auditor Agent

## Problem
Render blocks Gmail SMTP on port 587, so confirmation emails can't be sent.

## Solution 1: Disable Email Verification (FASTEST - 2 minutes)

### In Render Dashboard:
1. Go to https://dashboard.render.com
2. Click your service "legastream"
3. Go to "Environment" tab
4. Change `DEVELOPMENT_MODE` from `false` to `true`
5. Save (auto-redeploys)

**Result:** Users can register and login immediately without email confirmation.

---

## Solution 2: Use SendGrid (BEST - 10 minutes)

### Step 1: Sign Up for SendGrid (FREE)
1. Go to https://signup.sendgrid.com/
2. Sign up with your email: enginboy20@gmail.com
3. Verify your email
4. Complete the "Tell us about yourself" form:
   - Role: Developer
   - Company: Your company name
   - Website: https://legastream.onrender.com

### Step 2: Create API Key
1. In SendGrid dashboard, go to Settings → API Keys
2. Click "Create API Key"
3. Name: "Legal Auditor Agent Production"
4. Permission: "Full Access"
5. Click "Create & View"
6. **COPY THE KEY** (starts with `SG.`) - you won't see it again!

### Step 3: Verify Sender Email
1. Go to Settings → Sender Authentication
2. Click "Verify a Single Sender"
3. Fill in:
   - From Name: Legal Auditor Agent
   - From Email: enginboy20@gmail.com
   - Reply To: enginboy20@gmail.com
   - Company: Your company
   - Address: Any address
4. Submit
5. Check your email and click the verification link

### Step 4: Add to Render
1. Go to Render dashboard → Your service → Environment
2. Add new environment variable:
   - Key: `SENDGRID_API_KEY`
   - Value: `SG.your_api_key_here` (paste the key you copied)
3. Optional: Add these too:
   - Key: `SMTP_FROM_EMAIL`
   - Value: `enginboy20@gmail.com`
   - Key: `SMTP_FROM_NAME`
   - Value: `Legal Auditor Agent`
4. Make sure `DEVELOPMENT_MODE` is set to `false`
5. Save Changes (auto-redeploys)

### Step 5: Test
1. Visit https://legastream.onrender.com
2. Register a new account
3. Check your email for confirmation link
4. Click link to confirm
5. Login!

---

## Why SendGrid Works When Gmail Doesn't

- Gmail SMTP uses port 587 → Render blocks it
- SendGrid uses their API → Render allows it
- SendGrid is designed for cloud apps
- 100 emails/day FREE forever
- Better deliverability (won't go to spam)

---

## Current Status

✅ App is deployed and working
✅ Frontend is serving correctly
✅ Registration creates accounts
✅ Login works
🔴 Email sending blocked by Render

**Choose your solution:**
- Need it working NOW? → Use Solution 1 (DEVELOPMENT_MODE=true)
- Want proper emails? → Use Solution 2 (SendGrid)
- Want both? → Start with Solution 1, then add Solution 2 later

The code already supports both options - just change the environment variables!
