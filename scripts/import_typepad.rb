require "open-uri"
require "nokogiri"
require "playwright"
require "tempfile"
require "cgi"
require_relative "import_helpers"

# Helper: Download an image via Playwright to bypass Cloudflare JS
def download_typepad_image(url)
  file = nil

  Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
    browser = playwright.chromium.launch(
      headless: true,
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-dev-shm-usage',
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-gpu',
        '--disable-features=VizDisplayCompositor'
      ]
    )

    begin
      # Create browser context with realistic settings
      context = browser.new_context(
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        viewport: { 'width' => 1920, 'height' => 1080 },
        extraHTTPHeaders: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Accept-Encoding' => 'gzip, deflate, br',
          'DNT' => '1',
          'Connection' => 'keep-alive',
          'Upgrade-Insecure-Requests' => '1'
        }
      )

      page = context.new_page

      # Navigate to the image URL and capture the response
      response = page.goto(url)
      page.wait_for_load_state

      # Get the response body as bytes
      binary = response.body

      # Ensure binary data is in correct encoding
      binary = binary.force_encoding('ASCII-8BIT') if binary.respond_to?(:force_encoding)

      # Write to tempfile - extract extension from URL path
      url_path = URI.parse(url).path
      ext = File.extname(url_path)
      ext = '.jpg' if ext.empty?

      file = Tempfile.new([ 'image', ext ])
      file.binmode
      file.write(binary)
      file.rewind

    ensure
      browser.close if browser
    end
  end

  file
end

# Custom TypePad image processing that uses Playwright but follows the helper pattern
def process_images_to_actiontext_typepad(html_content)
  processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)

  processed_content.css("img").each do |img|
    image_src = img["src"]
    alt_text = img["alt"] || ""
    next unless image_src
    next if image_src.include?("rails/active_storage") || image_src.start_with?("data:")

    begin
      # Use TypePad-specific download method
      puts "  Downloading image: #{image_src}"
      file = download_typepad_image(image_src)
      puts "  ✓ Downloaded successfully"

      filename = File.basename(URI.parse(image_src).path)
      filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')

      # Create blob (same as helper)
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)
      puts "  ✓ Blob created: #{blob.filename} (#{blob.byte_size} bytes)"

      # Create ActionText attachment with optional caption (same as helper)
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
      img.replace(attachment_node)
      puts "  ✓ Image attached to post content"
    rescue => e
      raise "Failed to process image #{image_src}: #{e.message}"
    ensure
      file.close! if file
    end
  end

  processed_content.to_html
end

# Usage: ruby import_typepad.rb path/to/typepad_export.txt blog_subdomain [--dry-run]
def import_typepad(file_path, blog_subdomain, dry_run = false)
  include ImportHelpers
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  content = File.read(file_path)
  all_entries = content.split("--------").map(&:strip).reject(&:empty?)
  entries = all_entries.reject { |entry| entry.include?('COMMENT:') }

  puts "Found #{all_entries.length} total entries (#{entries.length} posts, #{all_entries.length - entries.length} comments)"

  # Pre-process slugs
  potential_slugs = Hash.new(0)
  entry_metadata = []

  entries.each do |entry|
    sections = entry.split("-----")
    next if sections.length < 2

    header_section = sections[0].strip
    fields = {}

    header_section.lines.each do |line|
      line = line.strip
      next if line.empty?
      if line.include?(':')
        key, value = line.split(':', 2)
        fields[key.strip.upcase] = value.strip
      end
    end

    title = fields['TITLE']
    title = ActionText::Content.new(title).to_plain_text.strip if title&.present?

    basename = fields['BASENAME']&.strip&.gsub('_', '-')&.gsub(/-+/, '-')&.gsub(/^-|-$/, '')
    unique_url = fields['UNIQUE URL']

    base_slug = if basename.present?
                  basename
    elsif title.present?
                  title.parameterize.truncate(100, omission: "").gsub(/-+\z/, "")
    end

    potential_slugs[base_slug] += 1 if base_slug.present?

    entry_metadata << {
      title: title,
      basename: basename,
      unique_url: unique_url,
      base_slug: base_slug,
      fields: fields
    }
  end

  success_count = 0
  failed_count = 0
  skipped_count = 0

  entries.each_with_index do |entry, index|
    puts "Processing entry #{index + 1} of #{entries.length}"
    begin
      metadata = entry_metadata[index]
      sections = entry.split("-----")
      next if sections.length < 2
      header_section = sections[0].strip
      body_section = sections[1].strip if sections[1]
      next unless body_section

      categories = []
      header_section.lines.each do |line|
        next if line.strip.empty?
        if line.include?(':')
          key, value = line.split(':', 2)
          categories << value if key.strip.upcase == 'CATEGORY'
        end
      end

      title = metadata[:title]
      basename = metadata[:basename]
      unique_url = metadata[:unique_url]
      base_slug = metadata[:base_slug]
      fields = metadata[:fields]

      date_str = fields['DATE']
      status = fields['STATUS']

      if basename.present?
        basename = basename.gsub('_', '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
      end

      published_at = if date_str.present?
                       begin
                         Time.strptime(date_str, "%m/%d/%Y %I:%M:%S %p")
                       rescue
                         parse_datetime(date_str, fallback_message: "Warning: Could not parse date '#{date_str}' for '#{title}'")
                       end
      else
                       Time.current
      end

      post_status = (status == "Publish") ? "published" : "draft"

      slug = if base_slug.present? && potential_slugs[base_slug] > 1 && unique_url.present?
               if match = unique_url.match(/\/(\d{4})\/(\d{2})\//)
                 "#{base_slug}-#{match[1]}-#{match[2]}"
               else
                 base_slug
               end
      else
               base_slug
      end

      tag_list = categories.map { |category| clean_tag(category) }.reject(&:empty?).uniq.sort

      # Check if post already exists by title or slug
      existing_post = post_exists?(blog, title)

      # Also check by slug if we have one
      if !existing_post && slug.present?
        existing_post = blog.all_posts.find_by(slug: slug)
      end

      if existing_post
        display_title = title.presence || "[Untitled]"
        puts "Skipping duplicate post: #{display_title} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
        skipped_count += 1
        next
      end

      html_content = body_section.gsub(/^BODY:\s*/, '')
      post = blog.all_posts.new(
        title: title,
        published_at: published_at,
        status: post_status,
        tag_list: tag_list,
        is_page: false,
        show_in_navigation: false
      )
      post.slug = slug

      # Process images and create ActionText content
      begin
        if dry_run
          # For dry run, just count images without processing
          parsed_html = Nokogiri::HTML::DocumentFragment.parse(html_content)
          image_count = parsed_html.css("img").count
          puts "[DRY RUN] Would process #{image_count} images" if image_count > 0
          post.content = html_content
        else
          post.content = process_images_to_actiontext_typepad(html_content)
        end
      rescue => e
        puts "Skipping post due to image processing failure: #{title || '[Untitled]'} - #{e.message}"
        failed_count += 1
        next
      end

      display_title = title.presence || "[Untitled]"
      if dry_run
        puts "[DRY RUN] Would create post: #{display_title}, Status: #{post_status}, Published at: #{published_at}, Slug: #{slug}"
        success_count += 1 if post.valid?
        failed_count += 1 unless post.valid?
        next
      end

      if post.save
        post.update_column(:slug, slug) if post.slug != slug
        puts "Successfully created post: #{display_title} (slug: #{slug})"
        success_count += 1
      else
        puts "Failed to create post: #{display_title}"
        puts post.errors.full_messages
        failed_count += 1
      end

    rescue => e
      puts "Error processing entry #{index + 1}: #{e.message}"
      failed_count += 1
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Total posts processed: #{entries.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped: #{skipped_count}"
  puts "====================="
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2 || ARGV.length > 3
    puts "Usage: bundle exec rails runner import_typepad.rb path/to/typepad_export.txt blog_subdomain [--dry-run]"
    return
  end

  file_path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV[2] == '--dry-run'

  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    return
  end

  puts "=== DRY RUN MODE - No posts will be created ===" if dry_run
  import_typepad(file_path, blog_subdomain, dry_run)
end
