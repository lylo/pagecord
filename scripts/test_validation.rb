require 'nokogiri'
require 'date'

# Test validation on a single entry without requiring the main script
html_content = File.read('/Users/olly/Downloads/dreamwidth-dump-html/entries/entry-99.html')
doc = Nokogiri::HTML(html_content)

# Extract title
title_element = doc.at_css("h3.entry-title")
title = title_element ? title_element.text.strip : nil

# Extract date
datetime_element = doc.at_css(".header .datetime")
if datetime_element
  published_at = DateTime.parse("Jul. 22, 2007 11:53 AM")
else
  puts "No datetime found"
  exit
end

# Extract content
content_element = doc.at_css(".entry-content")
content = content_element.inner_html if content_element

# Process content
processed_content = content

# Extract and process tags
tag_elements = doc.css('.tag ul li a')
tags = tag_elements.map do |tag_element|
  tag_text = tag_element.text.strip

  if tag_text.include?(':')
    parts = tag_text.split(':')
    raw_tag = parts.last.strip
  else
    raw_tag = tag_text
  end

  sanitized_tag = raw_tag
    .gsub(/\s+/, '-')
    .gsub(/[^\w\-]/, '')
    .gsub(/-+/, '-')
    .gsub(/^-|-$/, '')
    .downcase

  sanitized_tag.empty? ? nil : sanitized_tag
end.compact.uniq

puts "Title: '#{title}'"
puts "Title length: #{title&.length || 0}"
puts "Content length: #{processed_content&.bytesize || 0} bytes"
puts "Tags: #{tags.inspect}"
puts "Content valid: #{processed_content && !processed_content.gsub(/<[^>]*>/, '').strip.empty?}"

# Try to find a blog to test with
blog = Blog.first
if blog
  puts "Testing with blog: #{blog.subdomain}"

  post = blog.posts.build(
    title: title.present? ? title : nil,
    published_at: published_at,
    tag_list: tags
  )

  post.content = processed_content

  puts "Post valid: #{post.valid?}"
  unless post.valid?
    puts "Validation errors: #{post.errors.full_messages.join(', ')}"
  end
else
  puts "No blog found for testing"
end
