require 'nokogiri'

# Test the tag extraction on the problematic entry
html_content = File.read('/Users/olly/Downloads/dreamwidth-dump-html/entries/entry-99.html')
doc = Nokogiri::HTML(html_content)

tag_elements = doc.css('.tag ul li a')

puts "Raw tags from entry-99.html:"
tag_elements.each do |tag_element|
  puts "  '#{tag_element.text.strip}'"
end

puts "\nProcessed tags:"
tags = tag_elements.map do |tag_element|
  tag_text = tag_element.text.strip

  # Handle hierarchical tags like "hobbies: food" or "social: ex friends: amanda"
  if tag_text.include?(':')
    # Take the last part after the final colon and strip whitespace
    parts = tag_text.split(':')
    raw_tag = parts.last.strip
  else
    raw_tag = tag_text
  end

  # Sanitize tag to only allow alphanumeric characters and hyphens
  # Convert spaces to hyphens, remove brackets and other special characters
  sanitized_tag = raw_tag
    .gsub(/\s+/, '-')           # Convert spaces to hyphens
    .gsub(/[^\w\-]/, '')        # Remove all non-alphanumeric chars except hyphens
    .gsub(/-+/, '-')            # Collapse multiple hyphens into one
    .gsub(/^-|-$/, '')          # Remove leading/trailing hyphens
    .downcase                   # Convert to lowercase for consistency

  # Only return non-empty tags with reasonable length
  if sanitized_tag.empty? || sanitized_tag.length > 50
    nil
  else
    sanitized_tag
  end
end.compact.uniq

# Limit to a reasonable number of tags (e.g., 20)
tags = tags.first(20)

tags.each do |tag|
  puts "  '#{tag}'"
end

puts "\nExpected result: ['food', 'jeff-father', 'annoyances', 'amanda']"
