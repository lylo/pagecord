require "redcarpet"
require "open-uri"
require "nokogiri"

# Usage: ruby import_markdown.rb path/to/markdown/directory_or_file blog_subdomain [--dry-run]
def import_markdown(path, blog_subdomain, dry_run = false)
  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  # Find all markdown files - handle both single files and directories
  markdown_files = []

  if File.file?(path)
    if path.end_with?('.md')
      markdown_files = [ path ]
    else
      puts "File #{path} is not a markdown file (must end with .md)"
      return
    end
  elsif File.directory?(path)
    markdown_files = Dir.glob(File.join(path, "*.md"))
    if markdown_files.empty?
      puts "No markdown files found in #{path}"
      return
    end
  else
    puts "Path not found: #{path}"
    return
  end

  puts "Found #{markdown_files.length} markdown files to import"

  # Setup markdown parser with HTML rendering
  renderer = Redcarpet::Render::HTML.new(
    filter_html: false,
    no_intra_emphasis: true,
    fenced_code_blocks: true,
    disable_indented_code_blocks: true,
    autolink: true,
    tables: true,
    underline: true,
    highlight: true
  )

  markdown_parser = Redcarpet::Markdown.new(renderer, {
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    superscript: true
  })

  success_count = 0
  failed_count = 0
  skipped_count = 0

  markdown_files.each do |file_path|
    puts "Processing file: #{File.basename(file_path)}"

    # Read and parse the markdown file
    content = File.read(file_path)

    # Extract front matter
    front_matter = {}
    content = content.strip  # Remove leading/trailing whitespace
    markdown_content = content

    if content.start_with?('---')
      parts = content.split('---', 3)
      if parts.length >= 3
        front_matter_text = parts[1].strip
        markdown_content = parts[2].strip

        # Parse front matter (simple YAML-like parsing)
        front_matter_text.lines.each do |line|
          line = line.strip
          next if line.empty?

          if line.include?(':')
            key, value = line.split(':', 2)
            front_matter[key.strip.downcase] = value.strip
          end
        end
      end
    end

    # Convert markdown to HTML
    html_content = markdown_parser.render(markdown_content)
    parsed_html = Nokogiri::HTML::DocumentFragment.parse(html_content)

    # Find the first non-empty element
    first_element = parsed_html.children.find { |child| !child.text.strip.empty? }

    # Extract title from H1 if it's the first element in the HTML, then remove it from the content
    title = nil
    if first_element && first_element.name == 'h1'
      title = first_element.text.strip
      first_element.remove
      html_content = parsed_html.to_html
    end

    # Parse published date
    published_at = nil
    if front_matter['date']
      begin
        published_at = Time.parse(front_matter['date'])
      rescue ArgumentError
        puts "Warning: Could not parse date '#{front_matter['date']}' for #{File.basename(file_path)}"
        published_at = Time.current
      end
    else
      published_at = Time.current
    end

    # Parse tags
    tag_list = []
    if front_matter['tags']
      tag_list = front_matter['tags'].split(',').map do |tag|
        # Clean up the tag: strip whitespace, replace spaces with hyphens, keep only alphanumeric and hyphens
        tag.strip.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
      end.reject(&:empty?)
    end

    # Check if it's a page
    is_page = front_matter['type'] == 'page'

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
      puts "Skipping duplicate post: #{title || File.basename(file_path)} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
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

    # Process HTML content for images and convert them to ActionText attachments
    processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)
    image_processing_failed = false

    processed_content.css("img").each do |img|
      image_src = img["src"]
      next unless image_src
      next if image_src.include?("rails/active_storage") || image_src.start_with?("data:")

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
        attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
        puts "ATTACHMENT NODE"
        puts attachment_node
        img.replace(attachment_node)
      rescue => e
        puts "Failed to process image #{image_src}: #{e.message}"
        image_processing_failed = true
        break
      end
    end

    # Skip this post if image processing failed
    if image_processing_failed
      puts "Skipping post due to image processing failure: #{title || File.basename(file_path)}"
      failed_count += 1
      next
    end

    # Assign processed HTML into ActionText
    puts "PROCESSED CONTENT BEFORE SAVE:"
    puts processed_content.to_html
    post.content = processed_content.to_html

    puts "PROCESSED CONTENT AFTER ASSIGNMENT:"
    puts post.content

    if dry_run
      puts "[DRY RUN] Would create #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
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
      puts "Successfully created #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
      success_count += 1
    else
      puts "Failed to create #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
      puts post.errors.full_messages
      failed_count += 1
      next
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Total files processed: #{markdown_files.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped (duplicates): #{skipped_count}"
  puts "====================="
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2 || ARGV.length > 3
    puts "Usage: bundle exec rails runner import_markdown.rb path/to/markdown/directory_or_file blog_subdomain [--dry-run]"
    puts "Examples:"
    puts "  bundle exec rails runner import_markdown.rb ./markdown_posts myblog"
    puts "  bundle exec rails runner import_markdown.rb ./single_post.md myblog --dry-run"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV[2] == '--dry-run'

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_markdown(path, blog_subdomain, dry_run)
end
