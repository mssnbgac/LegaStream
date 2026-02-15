# SendGrid Setup (Recommended for Render)

SendGrid is more reliable than Gmail SMTP for cloud deployments.

## Why SendGrid?
- ✅ Designed for cloud applications
- ✅ 100 emails/day FREE forever
- ✅ Works reliably from Render
- ✅ Better deliverability than Gmail
- ✅ No IP blocking issues

## Setup Steps:

### 1. Create SendGrid Account
1. Go to: https://signup.sendgrid.com/
2. Sign up with your email (enginboy20@gmail.com)
3. Verify your email address
4. Complete the onboarding

### 2. Create API Key
1. Go to Settings → API Keys
2. Click "Create API Key"
3. Name it: "LegaStream Production"
4. Select "Full Access"
5. Copy the API key (starts with "SG.")

### 3. Verify Sender Identity
1. Go to Settings → Sender Authentication
2. Click "Verify a Single Sender"
3. Enter your details:
   - From Email: enginboy20@gmail.com
   - From Name: LegaStream
4. Check your email and verify

### 4. Update Render Environment Variables

Replace Gmail SMTP settings with:

```
SENDGRID_API_KEY=SG.your_api_key_here
SMTP_FROM_EMAIL=enginboy20@gmail.com
SMTP_FROM_NAME=LegaStream
```

### 5. Update production_server.rb

I'll update the code to support SendGrid automatically.

## Alternative: Mailgun
- 5,000 emails/month free for 3 months
- Then 1,000 emails/month free forever
- Setup: https://www.mailgun.com/

## Alternative: Resend
- 3,000 emails/month free forever
- Modern, developer-friendly
- Setup: https://resend.com/
