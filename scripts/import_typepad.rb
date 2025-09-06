require "open-uri"
require "nokogiri"

# Usage: ruby import_typepad.rb path/to/typepad_export.txt blog_subdomain [--dry-run]
def import_typepad(file_path, blog_subdomain, dry_run = false)
  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  # Read and parse the Typepad export file
  content = File.read(file_path)
  all_entries = content.split("--------").map(&:strip).reject(&:empty?)

  # Filter out comments before processing
  entries = all_entries.reject { |entry| entry.include?('COMMENT:') }

  puts "Found #{all_entries.length} total entries (#{entries.length} posts, #{all_entries.length - entries.length} comments)"

  # Pre-process all entries to detect slug duplicates within THIS import file
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

    # Extract and clean up title
    title = fields['TITLE']
    if title&.present?
      title = ActionText::Content.new(title).to_plain_text.strip
    end

    basename = fields['BASENAME']&.strip&.gsub('_', '-')&.gsub(/-+/, '-')&.gsub(/^-|-$/, '')
    unique_url = fields['UNIQUE URL']

    # Determine what the base slug would be
    base_slug = nil
    if basename.present?
      base_slug = basename
    elsif title.present?
      base_slug = title.parameterize.truncate(100, omission: "").gsub(/-+\z/, "")
    end

    if base_slug.present?
      potential_slugs[base_slug] += 1
    end

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
      # Get pre-processed metadata for this entry
      metadata = entry_metadata[index]

      # Parse the entry into sections
      sections = entry.split("-----")

      # Skip if this doesn't look like a valid entry
      next if sections.length < 2

      header_section = sections[0].strip
      body_section = sections[1].strip if sections[1]

      # Parse header fields for categories
      categories = []
      header_section.lines.each do |line|
        line = line.strip
        next if line.empty?

        if line.include?(':')
          key, value = line.split(':', 2)
          key = key.strip.upcase

          if key == 'CATEGORY'
            categories << value
          end
        end
      end

      # Use pre-processed metadata
      title = metadata[:title]
      basename = metadata[:basename]
      unique_url = metadata[:unique_url]
      base_slug = metadata[:base_slug]
      fields = metadata[:fields]

      # Skip entries without essential fields (body is required, title is optional)
      unless body_section
        puts "Skipping post due to missing body content"
        skipped_count += 1
        next
      end

      # Extract other fields
      date_str = fields['DATE']
      status = fields['STATUS']

      # Clean basename: convert underscores to hyphens, collapse multiple hyphens, remove leading/trailing hyphens
      if basename.present?
        basename = basename.gsub('_', '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
      end

      # Parse published date
      published_at = nil
      if date_str
        begin
          # Typepad format appears to be MM/DD/YYYY HH:MM:SS AM/PM
          published_at = Time.strptime(date_str, "%m/%d/%Y %I:%M:%S %p")
        rescue ArgumentError
          puts "Warning: Could not parse date '#{date_str}' for '#{title}'"
          published_at = Time.current
        end
      else
        published_at = Time.current
      end

      # Determine post status
      post_status = (status == "Publish") ? "published" : "draft"

      # Generate final slug - add date suffix ONLY if this base_slug appears multiple times in import file
      slug = nil

      if base_slug.present? && potential_slugs[base_slug] > 1 && unique_url.present?
        # Extract year/month from unique URL for disambiguation
        if match = unique_url.match(/\/(\d{4})\/(\d{2})\//)
          year, month = match[1], match[2]
          slug = "#{base_slug}-#{year}-#{month}"
        else
          slug = base_slug
        end
      else
        slug = base_slug
      end

      # Process categories into normalized tags
      tag_list = []
      if categories.any?
        tag_list = categories.map do |category|
          # Normalize category to match Taggable::VALID_TAG_FORMAT
          normalized = category.strip.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
          # Remove multiple consecutive hyphens and leading/trailing hyphens
          normalized.gsub(/-+/, '-').gsub(/^-|-$/, '')
        end.reject(&:blank?).select do |tag|
          # Only keep tags that match the valid format
          tag.match?(/\A[a-zA-Z0-9-]+\z/)
        end.uniq.sort
      end

      # Check if post already exists by slug and published_at
      existing_post = nil
      if slug.present?
        existing_post = blog.all_posts.find_by(slug: slug, published_at: published_at)

        # If no exact match, also check for slug with close published_at (within 1 minute)
        if !existing_post
          time_range = (published_at - 1.minute)..(published_at + 1.minute)
          existing_post = blog.all_posts.where(
            slug: slug,
            published_at: time_range
          ).first
        end
      end

      if existing_post
        display_title = title.present? ? title : "[Untitled]"
        puts "Skipping duplicate post: #{display_title} (slug: '#{existing_post.slug}', published_at: #{existing_post.published_at})"
        skipped_count += 1
        next
      end

      # Clean up the body content
      html_content = body_section
      html_content = html_content.gsub(/^BODY:\s*/, '')

      # Create the Post object (without content yet, so we don't trigger ActionText parsing of <img>)
      post = blog.all_posts.new(
        title: title,
        published_at: published_at,
        status: post_status,
        tag_list: tag_list,
        is_page: false,
        show_in_navigation: false
      )

      # Set slug after creation to avoid Sluggable concern overriding it
      post.slug = slug

      # Process HTML content for images and convert them to ActionText attachments
      processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)
      image_processing_failed = false

      unless dry_run
        processed_content.css("img").each do |img|
          image_src = img["src"]
          next unless image_src
          next if image_src.include?("rails/active_storage") || image_src.start_with?("data:")

          begin
            # Basic image download using URI.open
            file = URI.open(
              image_src,
              "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
              "Referer" => "https://#{URI.parse(image_src).host}/",
              "Cookie" => "__cf_bm=...."
            )
            content_type = file.meta["content-type"]
            unless content_type&.start_with?("image/")
              raise "Expected image, got #{content_type}"
            end

            filename = File.basename(URI.parse(image_src).path)
            filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')

            # Create blob
            blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)

            # Replace the <img> with the ActionText attachable representation
            attachment_node = ActionText::Content.new("").append_attachables([ blob ]).to_trix_html
            img.replace(attachment_node)
          rescue => e
            puts "Failed to process image #{image_src}: #{e.message}"
            image_processing_failed = true
            break
          end
        end
      else
        # In dry run mode, just count images that would be processed
        image_count = processed_content.css("img").count
        if image_count > 0
          puts "[DRY RUN] Would process #{image_count} images"
        end
      end

      # Skip this post if image processing failed
      if image_processing_failed
        display_title = title.present? ? title : "[Untitled]"
        puts "Skipping post due to image processing failure: #{display_title}"
        failed_count += 1
        next
      end

      # Assign processed HTML into ActionText
      post.content = processed_content.to_html

      display_title = title.present? ? title : "[Untitled]"

      if dry_run
        puts "[DRY RUN] Would create post: #{display_title}"
        puts "[DRY RUN] Status: #{post_status}"
        puts "[DRY RUN] Published at: #{published_at}"
        puts "[DRY RUN] Slug: #{slug || 'auto-generated'}"
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
        # Update slug directly after saving to override Sluggable concern
        if post.slug != slug
          post.update_column(:slug, slug)
          puts "Successfully created post: #{display_title} (slug: #{slug})"
        else
          puts "Successfully created post: #{display_title}"
        end
        success_count += 1
      else
        puts "Failed to create post: #{display_title}"
        puts post.errors.full_messages
        failed_count += 1
      end

    rescue => e
      puts "Error processing entry #{index + 1}: #{e.message}"
      puts "Entry preview: #{entry[0..200]}..."
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

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2 || ARGV.length > 3
    puts "Usage: bundle exec rails runner import_typepad.rb path/to/typepad_export.txt blog_subdomain [--dry-run]"
    puts "Examples:"
    puts "  bundle exec rails runner import_typepad.rb export.txt myblog"
    puts "  bundle exec rails runner import_typepad.rb export.txt myblog --dry-run"
    return
  end

  file_path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV[2] == '--dry-run'

  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    return
  end

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_typepad(file_path, blog_subdomain, dry_run)
end
