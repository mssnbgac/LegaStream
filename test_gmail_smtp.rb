#!/usr/bin/env ruby
require 'mail'
require 'dotenv/load'

puts "Testing Gmail SMTP Configuration"
puts "=" * 50

# Load credentials
smtp_host = ENV['SMTP_HOST']
smtp_port = ENV['SMTP_PORT']
smtp_user = ENV['SMTP_USERNAME']
smtp_pass = ENV['SMTP_PASSWORD']

puts "Host: #{smtp_host}"
puts "Port: #{smtp_port}"
puts "Username: #{smtp_user}"
puts "Password: #{smtp_pass ? '[SET - ' + smtp_pass.length.to_s + ' chars]' : '[NOT SET]'}"
puts "=" * 50

# Configure Mail
Mail.defaults do
  delivery_method :smtp, {
    address: smtp_host,
    port: smtp_port.to_i,
    user_name: smtp_user,
    password: smtp_pass,
    authentication: 'plain',
    enable_starttls_auto: true,
    openssl_verify_mode: 'none'
  }
end

# Send test email
begin
  puts "\nSending test email..."
  
  mail = Mail.new do
    from     smtp_user
    to       smtp_user  # Send to yourself
    subject  'LegaStream SMTP Test'
    body     "This is a test email from LegaStream.\n\nIf you receive this, your SMTP configuration is working correctly!\n\nTimestamp: #{Time.now}"
  end
  
  mail.deliver!
  
  puts "✅ SUCCESS! Email sent successfully!"
  puts "Check your inbox at: #{smtp_user}"
  puts "\nIf the email doesn't arrive within 2 minutes:"
  puts "1. Check your spam/junk folder"
  puts "2. Verify the app password is correct"
  puts "3. Make sure 2FA is enabled on your Google account"
  
rescue => e
  puts "❌ FAILED! Could not send email"
  puts "\nError: #{e.class}"
  puts "Message: #{e.message}"
  puts "\nCommon fixes:"
  puts "1. Regenerate your Gmail app password"
  puts "2. Make sure 2-Factor Authentication is enabled"
  puts "3. Try using port 465 with SSL instead of 587 with STARTTLS"
  puts "\nFull error details:"
  puts e.backtrace.first(5).join("\n")
end
