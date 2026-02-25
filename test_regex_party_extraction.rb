text = <<~TEXT
  EMPLOYMENT AGREEMENT

  This Employment Agreement ("Agreement") is made and entered into as of March 1, 2026,
  by and between Acme Corporation ("Employer") and John Smith ("Employee").
TEXT

puts "Testing regex party extraction..."
puts "=" * 80
puts ""

parties = []
skip_words = %w[This That These Those Agreement Contract Employee Employer Party Parties Between And Or With From To By For Of The In On At As Is Are Was Were Be Been Being Have Has Had Do Does Did Will Would Should Could May Might Must Can Shall]

# Extract company names
text.scan(/\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,4})\s+(Corporation|Corp\.?|Inc\.?|LLC|Ltd\.?|Limited|Company|Co\.?|Partnership|LLP|PC|PA|PLC|Plc|Bank|Solutions|Technologies|Services|Group|Holdings|Enterprises)\b/i) do |name, indicator|
  full_name = "#{name} #{indicator}".strip
  
  puts "Regex matched: '#{name}' + '#{indicator}' = '#{full_name}'"
  
  # Skip if too short
  if full_name.length < 5
    puts "  ❌ Skipped: too short"
    next
  end
  
  # Skip if contains ANY generic/common words
  words_in_name = full_name.split
  matching_skip_words = words_in_name & skip_words
  
  if matching_skip_words.any?
    puts "  ❌ Skipped: contains skip words: #{matching_skip_words.join(', ')}"
    next
  end
  
  puts "  ✅ Accepted"
  parties << full_name
end

puts ""
puts "Total companies found: #{parties.length}"
parties.each { |p| puts "  - #{p}" }
