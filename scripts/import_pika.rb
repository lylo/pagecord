require "open-uri"
require "nokogiri"
require "cgi"

# Import Pika.page exported HTML files into Pagecord posts
# Usage: ruby import_pika.rb path/to/html/directory_or_file blog_subdomain [--dry-run] [--as-pages] [--title-suffix="suffix"]
def import_pika(path, blog_subdomain, dry_run = false, as_pages = false, title_suffix = nil)
  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  # Find all HTML files - handle both single files and directories
  html_files = []

  if File.file?(path)
    if path.end_with?('.html', '.htm')
      html_files = [ path ]
    else
      puts "File #{path} is not an HTML file (must end with .html or .htm)"
      return
    end
  elsif File.directory?(path)
    html_files = Dir.glob(File.join(path, "*.{html,htm}"))
    if html_files.empty?
      puts "No HTML files found in #{path}"
      return
    end
  else
    puts "Path not found: #{path}"
    return
  end

  puts "Found #{html_files.length} HTML files to import"
  if as_pages
    puts "All imports will be created as pages (is_page = true)"
  end

  success_count = 0
  failed_count = 0
  skipped_count = 0

  html_files.each do |file_path|
    puts "Processing file: #{File.basename(file_path)}"

    # Read and parse the HTML file
    html_content = File.read(file_path)
    doc = Nokogiri::HTML(html_content)

    # Extract content from <article> tag
    article = doc.at('article')
    unless article
      puts "Warning: No <article> tag found in #{File.basename(file_path)}, skipping"
      failed_count += 1
      next
    end

    # Extract title from <title> tag and strip blog suffix
    title = nil
    title_tag = doc.at('title')
    if title_tag
      title = title_tag.text.strip
      # Strip the title suffix if provided
      if title_suffix
        # Handle both HTML entity and decoded versions
        escaped_suffix = Regexp.escape(title_suffix)
        title = title.gsub(/ - #{escaped_suffix}\z/, '').strip
        # Also try with HTML entities decoded
        decoded_suffix = CGI.unescapeHTML(title_suffix)
        if decoded_suffix != title_suffix
          escaped_decoded_suffix = Regexp.escape(decoded_suffix)
          title = title.gsub(/ - #{escaped_decoded_suffix}\z/, '').strip
        end
      end
    end

    # If no title found, use filename as fallback
    if title.nil? || title.empty?
      title = File.basename(file_path, File.extname(file_path)).humanize
      puts "Warning: No title found in #{File.basename(file_path)}, using filename: #{title}"
    end

    # Extract publication time from <time> element with class "published-at"
    published_at = nil
    time_element = doc.at('time.published-at')
    if time_element
      datetime = time_element['datetime'] || time_element.text.strip
      begin
        published_at = Time.parse(datetime)
      rescue ArgumentError
        puts "Warning: Could not parse datetime '#{datetime}' for #{File.basename(file_path)}"
        published_at = Time.current
      end
    else
      published_at = Time.current
      puts "Warning: No publication time found in #{File.basename(file_path)}, using current time"
    end

    # Extract tags from footer
    tag_list = []
    footer = doc.at('footer')
    if footer
      site_tags_div = footer.at('div.site-tags')
      if site_tags_div
        tag_links = site_tags_div.css('a')
        tag_list = tag_links.map do |link|
          # Clean up the tag: strip whitespace, replace spaces with hyphens, keep only alphanumeric and hyphens
          link.text.strip.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
        end.reject(&:empty?)
      end
    end

    # Set is_page based on --as-pages option
    is_page = as_pages

    # Check if post already exists by title (case-insensitive) or slug
    existing_post = nil
    if title
      # Check for exact title match (case-insensitive)
      existing_post = blog.all_posts.where("LOWER(title) = LOWER(?)", title).first

      # Check for slug collision using the same logic as the model
      if !existing_post
        simple_slug = title.parameterize.truncate(100, omission: "").gsub(/-+\z/, "")
        existing_post = blog.all_posts.find_by(slug: simple_slug) if simple_slug.present?
      end
    end

    if existing_post
      puts "Skipping duplicate post: #{title} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
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

    # Step 1: Extract the <article> as basis of post
    article_content = article.dup

    # Remove the first <h1> if it matches the title
    if title
      first_h1 = article_content.at('h1')
      if first_h1 && first_h1.text.strip == title
        first_h1.remove
      end
    end

    # Step 2: Replace all <action-text-attachment> nodes with <img> tags
    article_content.css("action-text-attachment").each do |attachment|
      image_url = attachment['url']
      next unless image_url

      # Extract alt text from figcaption if present
      alt_text = ""
      figure = attachment.at('figure')
      if figure
        figcaption = figure.at('figcaption')
        if figcaption
          alt_text = CGI.unescapeHTML(figcaption.text.strip)
        end
      end

      # Create a simple img tag
      img_tag = "<img src=\"#{CGI.escapeHTML(image_url)}\" alt=\"#{CGI.escapeHTML(alt_text)}\">"
      attachment.replace(img_tag)
    end

    # Step 4: Process all img tags like import_markdown: download, create blobs, create trix attachments
    processed_content = Nokogiri::HTML::DocumentFragment.parse(article_content.to_html)
    image_processing_failed = false

    processed_content.css("img").each do |img|
      image_src = img["src"]
      alt_text = img["alt"] || ""
      next unless image_src

      begin
        # Download the image
        file = URI.open(image_src)
        filename = File.basename(URI.parse(image_src).path)
        filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')

        # Create blob
        blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)

        # Replace the <img> with the ActionText attachable representation
        # Create Trix figure with URL for editing support
        url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        trix_attributes = {
          sgid: blob.attachable_sgid,
          contentType: blob.content_type,
          filename: blob.filename.to_s,
          filesize: blob.byte_size,
          previewable: blob.previewable?,
          url: url
        }

        # Add caption if alt text exists
        if alt_text && !alt_text.empty?
          trix_attributes[:caption] = alt_text
        end

        attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
        img.replace(attachment_node)
      rescue => e
        puts "Failed to process image #{image_src}: #{e.message}"
        image_processing_failed = true
        break
      end
    end

    # Skip this post if image processing failed
    if image_processing_failed
      puts "Skipping post due to image processing failure: #{title}"
      failed_count += 1
      next
    end

    # Assign processed HTML into ActionText
    post.content = processed_content.to_html

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
  puts "Total files processed: #{html_files.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped (duplicates): #{skipped_count}"
  puts "====================="
end

# Process article content: remove duplicate title and convert action-text-attachments to img tags
def process_article_content(article, title)
  article_content = article.dup

  # Remove the first <h1> if it matches the title
  if title
    first_h1 = article_content.at('h1')
    if first_h1 && first_h1.text.strip == title
      first_h1.remove
    end
  end

  # Replace all <action-text-attachment> nodes with <img> tags
  article_content.css("action-text-attachment").each do |attachment|
    image_url = attachment['url']
    next unless image_url

    # Extract alt text from figcaption if present
    alt_text = ""
    figure = attachment.at('figure')
    if figure
      figcaption = figure.at('figcaption')
      if figcaption
        alt_text = CGI.unescapeHTML(figcaption.text.strip)
      end
    end

    # Create a simple img tag
    img_tag = "<img src=\"#{CGI.escapeHTML(image_url)}\" alt=\"#{CGI.escapeHTML(alt_text)}\">"
    attachment.replace(img_tag)
  end

  article_content
end

# Process all img tags: download images and create ActionText attachments
def process_images_to_actiontext(article_content)
  processed_content = Nokogiri::HTML::DocumentFragment.parse(article_content.to_html)

  processed_content.css("img").each do |img|
    image_src = img["src"]
    alt_text = img["alt"] || ""
    next unless image_src

    # Download the image
    file = URI.open(image_src)
    filename = File.basename(URI.parse(image_src).path)
    filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')

    # Create blob
    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)

    # Create ActionText attachment with optional caption
    url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    trix_attributes = {
      sgid: blob.attachable_sgid,
      contentType: blob.content_type,
      filename: blob.filename.to_s,
      filesize: blob.byte_size,
      previewable: blob.previewable?,
      url: url
    }

    # Add caption if alt text exists
    if alt_text && !alt_text.empty?
      trix_attributes[:caption] = alt_text
    end

    attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
    img.replace(attachment_node)
  end

  processed_content.to_html
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner import_pika.rb path/to/html/directory_or_file blog_subdomain [--dry-run] [--as-pages] [--title-suffix=\"suffix\"]"
    puts "Examples:"
    puts "  bundle exec rails runner import_pika.rb ./html_posts myblog"
    puts "  bundle exec rails runner import_pika.rb ./single_post.html myblog --dry-run"
    puts "  bundle exec rails runner import_pika.rb ./html_posts myblog --as-pages"
    puts "  bundle exec rails runner import_pika.rb ./html_posts myblog --title-suffix=\"My Blog Name\""
    puts "  bundle exec rails runner import_pika.rb ./html_posts myblog --dry-run --as-pages --title-suffix=\"My Blog\""
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?('--dry-run')
  as_pages = ARGV.include?('--as-pages')

  # Parse title-suffix argument
  title_suffix = nil
  title_suffix_arg = ARGV.find { |arg| arg.start_with?('--title-suffix=') }
  if title_suffix_arg
    title_suffix = title_suffix_arg.split('=', 2)[1]
    # Remove surrounding quotes if present
    title_suffix = title_suffix.gsub(/\A["']|["']\z/, '')
  end

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  if title_suffix
    puts "Will strip title suffix: \" - #{title_suffix}\""
  end

  import_pika(path, blog_subdomain, dry_run, as_pages, title_suffix)
end
