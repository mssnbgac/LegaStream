# ⚡ Quick Fix: Enable Email-Free Registration

## The Problem
Gmail SMTP is blocked by Render's network. Users can't receive confirmation emails.

## The Solution (30 seconds)
Enable development mode to bypass email confirmation.

## Steps

### 1. Go to Render Dashboard
Visit: https://dashboard.render.com/

### 2. Select Your Service
Click on your web service (the one running Legal Auditor Agent)

### 3. Go to Environment Tab
Click "Environment" in the left sidebar

### 4. Find DEVELOPMENT_MODE
Scroll down to find the `DEVELOPMENT_MODE` variable

### 5. Change Value
Change from: `false`
Change to: `true`

### 6. Save Changes
Click "Save Changes" button at the bottom

### 7. Wait for Redeploy
Render will automatically redeploy (takes 2-3 minutes)

## What This Does

**Before (with DEVELOPMENT_MODE=false):**
- User registers → Email sent → User must click link → Can login
- ❌ Email blocked by Render → User stuck

**After (with DEVELOPMENT_MODE=true):**
- User registers → Account auto-confirmed → Can login immediately
- ✅ No email needed → Works perfectly

## Is This Safe?

**For Testing/Initial Launch:** YES
- Perfect for testing the app
- Great for initial users
- No security issues for small user base

**For Production (Many Users):** Consider SendGrid
- Email verification prevents spam accounts
- SendGrid is free (100 emails/day)
- Takes 5 minutes to set up

## When to Switch Back

Once you set up SendGrid:
1. Add `SENDGRID_API_KEY` to Render
2. Change `DEVELOPMENT_MODE` back to `false`
3. Emails will work through SendGrid

## Test It

After enabling DEVELOPMENT_MODE:
1. Visit https://legastream.onrender.com
2. Click "Create one here" (register)
3. Fill in the form
4. Click "Sign up"
5. You'll see: "Registration successful! Your account is ready to use."
6. Login immediately - no email needed!

## Summary

**Time to fix:** 30 seconds
**Difficulty:** Very easy
**Result:** Fully working app

Just change one environment variable and your app works perfectly!
