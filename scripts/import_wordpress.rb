require "open-uri"
require "nokogiri"
require "cgi"
require_relative "import_helpers"

# Import WordPress WXR exported XML files into Pagecord posts
# Usage: ruby import_wordpress.rb path/to/export.xml blog_subdomain [--dry-run]
def import_wordpress(path, blog_subdomain, dry_run = false)
  include ImportHelpers

  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  unless File.file?(path)
    puts "File not found: #{path}"
    return
  end

  unless path.end_with?('.xml')
    puts "File #{path} is not an XML file (must end with .xml)"
    return
  end

  puts "Reading WordPress export from #{path}"
  xml_content = File.read(path)
  doc = Nokogiri::XML(xml_content)

  # Remove default namespace to make XPath queries simpler
  doc.remove_namespaces!

  # Extract all items (posts/pages)
  items = doc.xpath("//item")
  puts "Found #{items.length} items in WordPress export"
  puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved"

  success_count = 0
  failed_count = 0
  skipped_count = 0

  items.each do |item|
    # Extract post metadata
    title = item.at_xpath("title")&.text&.strip
    content_encoded = item.at_xpath("encoded")&.text&.strip
    post_date = item.at_xpath("post_date")&.text&.strip
    post_status = item.at_xpath("status")&.text&.strip
    post_type = item.at_xpath("post_type")&.text&.strip

    # Skip empty titles
    unless title && !title.empty?
      puts "Skipping item with no title"
      skipped_count += 1
      next
    end

    puts "Processing: #{title}"

    # Skip non-published posts
    unless post_status == "publish"
      puts "Skipping unpublished post: #{title} (status: #{post_status})"
      skipped_count += 1
      next
    end

    # Skip non-post types (attachments, etc.)
    unless post_type == "post" || post_type == "page"
      puts "Skipping non-post item: #{title} (type: #{post_type})"
      skipped_count += 1
      next
    end

    # Parse publication date
    published_at = parse_datetime(post_date, fallback_message: "Warning: Could not parse datetime '#{post_date}' for #{title}")

    # Extract categories as tags
    categories = item.xpath("category[@domain='category']").map { |cat| cat.text.strip }
    # Clean and normalize tags
    tag_list = categories.map { |cat| clean_tag(cat) }.reject(&:empty?)

    # Use post_type from XML to determine if this is a page
    is_page = (post_type == "page")

    # Check if post already exists by title (case-insensitive) or slug
    existing_post = post_exists?(blog, title)

    if existing_post
      puts "Skipping duplicate post: #{title} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_count += 1
      next
    end

    # Skip if no content
    if content_encoded.nil? || content_encoded.empty?
      puts "Skipping post with no content: #{title}"
      skipped_count += 1
      next
    end

    # Create the Post object (without content yet, so we don't trigger ActionText parsing of <img>)
    post = blog.all_posts.new(
      title: title,
      published_at: published_at,
      tag_list: tag_list,
      is_page: is_page,
      show_in_navigation: false
    )

    # Parse and clean HTML content
    doc = Nokogiri::HTML::DocumentFragment.parse(content_encoded)

    # Unwrap images from <a> tags (WordPress often links images to full-size versions)
    doc.css("a img").each do |img|
      link = img.parent
      link.replace(img) if link.name == "a"
    end

    # Mark images with pagecord="true" so they survive sanitization
    doc.css("img").each { |img| img["pagecord"] = "true" }

    # Sanitize HTML content (removes style attributes, etc.)
    sanitized_content = Html::Sanitize.new.transform(doc.to_html)

    # Clean up common WordPress/SAPO export mess
    cleaned_doc = Nokogiri::HTML::DocumentFragment.parse(sanitized_content)

    # Remove empty paragraphs and divs
    cleaned_doc.css("p, div").each do |el|
      el.remove if el.text.gsub(/\u00A0/, "").strip.empty? && el.css("img, figure, action-text-attachment").empty?
    end

    # Remove <br> tags inside block containers (ol, ul, blockquote)
    cleaned_doc.css("ol br, ul br, blockquote br").each(&:remove)

    # Consolidate multiple consecutive <br> tags into singles
    cleaned_doc.css("br").each do |br|
      br.remove while br.next_sibling&.name == "br"
    end

    # Trim leading/trailing empty nodes
    trim_leading_empty_nodes(cleaned_doc)
    trim_trailing_empty_nodes(cleaned_doc)

    # Process images (download and convert to ActionText attachments)
    post.content = process_images_to_actiontext(cleaned_doc.to_html, skip_on_error: true)

    if dry_run
      puts "[DRY RUN] Would create #{is_page ? 'page' : 'post'}: #{title}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Tags: #{tag_list.join(', ')}" if tag_list.any?
      puts "[DRY RUN] Content length: #{post.content.to_plain_text.length} characters"

      # Validate without saving
      if post.valid?
        puts "[DRY RUN] Post validation: PASSED"
        success_count += 1
      else
        puts "[DRY RUN] Post validation: FAILED"
        puts "[DRY RUN] Errors: #{post.errors.full_messages.join(', ')}"
        failed_count += 1
      end
      next
    end

    if post.save
      puts "Successfully created #{is_page ? 'page' : 'post'}: #{title}"
      success_count += 1
    else
      puts "Failed to create #{is_page ? 'page' : 'post'}: #{title}"
      puts post.errors.full_messages
      failed_count += 1
      next
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Total items processed: #{items.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped: #{skipped_count}"
  puts "====================="
end

# Helper methods for trimming empty nodes (similar to Trimmable concern)
def trim_leading_empty_nodes(node)
  while node.children.any?
    first_child = node.children.first

    if first_child.text? && first_child.text.gsub(/\u00A0/, "").strip.empty?
      first_child.remove
    elsif first_child.element?
      if first_child.name == "br"
        first_child.remove
      elsif ["div", "p"].include?(first_child.name)
        trim_leading_empty_nodes(first_child)
        if first_child.children.empty? && first_child.text.gsub(/\u00A0/, "").strip.empty?
          first_child.remove
        else
          break
        end
      else
        trim_leading_empty_nodes(first_child)
        break if node.children.first == first_child
      end
    else
      break
    end
  end
end

def trim_trailing_empty_nodes(node)
  while node.children.any?
    last_child = node.children.last

    if last_child.text? && last_child.text.gsub(/\u00A0/, "").strip.empty?
      last_child.remove
    elsif last_child.element?
      if last_child.name == "br"
        last_child.remove
      elsif ["div", "p"].include?(last_child.name)
        trim_trailing_empty_nodes(last_child)
        if last_child.children.empty? && last_child.text.gsub(/\u00A0/, "").strip.empty?
          last_child.remove
        else
          break
        end
      else
        trim_trailing_empty_nodes(last_child)
        break if node.children.last == last_child
      end
    else
      break
    end
  end
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner import_wordpress.rb path/to/export.xml blog_subdomain [--dry-run]"
    puts ""
    puts "Imports WordPress WXR export files into Pagecord"
    puts ""
    puts "Options:"
    puts "  --dry-run   Validate posts without creating them"
    puts ""
    puts "Note: Post type (post vs page) is determined from the WordPress export"
    puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner import_wordpress.rb ./export.xml myblog"
    puts "  bundle exec rails runner import_wordpress.rb ./export.xml myblog --dry-run"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?('--dry-run')

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_wordpress(path, blog_subdomain, dry_run)
end
