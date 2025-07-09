#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'date'
require 'fileutils'

class DreamwidthImporter
  def initialize(folder_path, blog_subdomain, dry_run: false, skip_images: false)
    @folder_path = folder_path
    @entries_path = File.join(folder_path, "entries")
    @images_path = File.join(folder_path, "images")
    @userpics_path = File.join(folder_path, "userpics")
    @dry_run = dry_run
    @skip_images = skip_images

    @blog = Blog.find_by(subdomain: blog_subdomain)
    unless @blog
      raise "Blog with subdomain '#{blog_subdomain}' not found. Available blogs: #{Blog.pluck(:subdomain).join(', ')}"
    end
    @created_count = 0
    @skipped_count = 0
    @error_count = 0

    unless Dir.exist?(@entries_path)
      raise "Entries folder not found at #{@entries_path}"
    end

    puts "Dreamwidth Import for blog: #{@blog.display_name}"
    puts "#{'[DRY RUN] ' if @dry_run}#{'[SKIP IMAGES] ' if @skip_images}Entries path: #{@entries_path}"
    puts "Images path: #{@images_path}" if Dir.exist?(@images_path) && !@skip_images
    puts "Userpics path: #{@userpics_path}" if Dir.exist?(@userpics_path) && !@skip_images
    puts ""
  end

  def import!
    entry_files = Dir.glob(File.join(@entries_path, "*.html")).sort

    puts "\nFound #{entry_files.count} entry files to process"

    entry_files.each_with_index do |file_path, index|
      puts "\n[#{index + 1}/#{entry_files.count}] Processing #{File.basename(file_path)}"

      begin
        import_entry(file_path)
      rescue => e
        @error_count += 1
        puts "  ERROR: Failed to import #{File.basename(file_path)}: #{e.message}"
        puts "  #{e.backtrace.first}" if Rails.env.development?
      end
    end

    puts "\n" + "="*50
    puts "✅ Import completed!"
    puts "#{'[DRY RUN] ' if @dry_run}Created: #{@created_count} posts"
    puts "Skipped: #{@skipped_count} posts"
    puts "Errors: #{@error_count} posts"
    if @dry_run
      puts ""
      puts "This was a dry run. Re-run without --dry-run to actually import the posts."
    end
    puts "="*50
  end

  private

  def import_entry(file_path)
    html_content = File.read(file_path)
    doc = Nokogiri::HTML(html_content)

    # Extract title from <h3 class="entry-title">
    title_element = doc.at_css("h3.entry-title")
    title = title_element ? extract_text_content(title_element) : nil

    # Extract date from <span class="datetime"> within <div class="header">
    datetime_element = doc.at_css(".header .datetime")
    unless datetime_element
      @skipped_count += 1
      puts "  SKIP: No datetime found"
      return
    end

    published_at = parse_datetime(datetime_element.text.strip)
    unless published_at
      @skipped_count += 1
      puts "  SKIP: Could not parse datetime: #{datetime_element.text.strip}"
      return
    end

    # Extract content from <div class="entry-content">
    content_element = doc.at_css(".entry-content")
    unless content_element
      @skipped_count += 1
      puts "  SKIP: No entry content found"
      return
    end

    # Process content and handle relative images by converting to ActionText attachments
    processed_content = process_content(content_element.dup)

    # Validate content isn't empty after processing
    if processed_content.gsub(/<[^>]*>/, '').strip.empty?
      @skipped_count += 1
      puts "  SKIP: Content is empty after processing"
      return
    end

    # Validate content length isn't excessive (Pagecord has a 64KB limit)
    if processed_content.bytesize > 64.kilobytes
      @skipped_count += 1
      puts "  SKIP: Content too large (#{processed_content.bytesize} bytes, max 64KB)"
      return
    end

    # Extract tags from <div class="tag"><ul><li> and handle hierarchical tags
    tag_list = extract_tags(doc)

    # Validate title length if present
    if title.present? && title.length > 255
      puts "  WARNING: Title too long (#{title.length} chars), truncating to 255 chars"
      title = title.truncate(255)
    end

    # Check for duplicates
    if post_already_exists?(title, published_at, processed_content)
      return
    end

    # Create the post
    post = @blog.posts.build(
      title: title.present? ? title : nil,
      published_at: published_at,
      tag_list: tag_list
    )

    # Set content as ActionText rich text
    post.content = processed_content

    # Validate the post before saving
    unless post.valid?
      @error_count += 1
      puts "  ERROR: Post validation failed: #{post.errors.full_messages.join(', ')}"
      return
    end

    if @dry_run
      @created_count += 1
      puts "  🔍 [DRY RUN] Would create: #{post.display_title}"
      puts "     Tags: [#{tag_list.join(', ')}]" if tag_list.any?
      puts "     Date: #{published_at.strftime('%Y-%m-%d %H:%M')}"
    elsif post.save
      @created_count += 1
      puts "  ✅ Created: #{post.display_title}"
      puts "     Tags: [#{tag_list.join(', ')}]" if tag_list.any?
      puts "     Date: #{published_at.strftime('%Y-%m-%d %H:%M')}"
    else
      @error_count += 1
      puts "  ERROR: Failed to save post: #{post.errors.full_messages.join(', ')}"
    end
  end

  def extract_text_content(element)
    # Get the text content, removing any nested anchor tags but keeping the text
    element.children.map do |child|
      if child.text?
        child.text
      elsif child.name == 'a'
        child.text
      else
        child.text
      end
    end.join.strip
  end

  def post_already_exists?(title, published_at, processed_content)
    # Create a simple identifier for duplicate detection
    content_preview = processed_content.gsub(/<[^>]*>/, '').strip.truncate(100)

    # Check if post already exists (by title and date, or by content if no title)
    if title.present?
      existing_post = @blog.posts.find_by(
        title: title,
        published_at: published_at.beginning_of_day..published_at.end_of_day
      )
      if existing_post
        @skipped_count += 1
        puts "  SKIP: Post already exists (#{title} - #{published_at.strftime('%Y-%m-%d')})"
        return true
      end
    else
      # If no title, check by date and content similarity
      same_day_posts = @blog.posts.where(
        published_at: published_at.beginning_of_day..published_at.end_of_day
      )

      existing_post = same_day_posts.find do |post|
        post_preview = post.content.to_plain_text.strip.truncate(100)
        post_preview == content_preview
      end

      if existing_post
        @skipped_count += 1
        puts "  SKIP: Similar content already exists for #{published_at.strftime('%Y-%m-%d')}"
        return true
      end
    end

    false
  end

  def parse_datetime(datetime_str)
    # Expected format: "Nov. 15, 2007 10:22 AM"
    # Let's try a few common patterns

    patterns = [
      "%b. %d, %Y %l:%M %p",  # Nov. 15, 2007 10:22 AM
      "%B %d, %Y %l:%M %p",   # November 15, 2007 10:22 AM
      "%b %d, %Y %l:%M %p",   # Nov 15, 2007 10:22 AM
      "%m/%d/%Y %l:%M %p"    # 11/15/2007 10:22 AM
    ]

    patterns.each do |pattern|
      begin
        return DateTime.strptime(datetime_str, pattern)
      rescue ArgumentError
        next
      end
    end

    # If none of the patterns work, try to extract with regex
    if match = datetime_str.match(/(\w+\.?\s+\d+,\s+\d{4})\s+(\d+:\d+\s+[AP]M)/i)
      date_part = match[1]
      time_part = match[2]

      begin
        return DateTime.parse("#{date_part} #{time_part}")
      rescue ArgumentError
        nil
      end
    end

    nil
  end

  def process_content(content_element)
    images_processed = 0

    # Convert relative image paths and embed images as ActionText attachments
    content_element.css('img').each do |img|
      src = img['src']
      next unless src

      if src.start_with?('../') && !@skip_images
        # This is a relative path - try to load the image
        image_path = resolve_image_path(src)

        if image_path && File.exist?(image_path)
          if @dry_run
            # In dry run, just log what we would do
            puts "    [DRY RUN] Would process image: #{File.basename(image_path)}"
            images_processed += 1
          else
            # Create an ActionText attachment
            puts "    DEBUG: Resolved image path: #{image_path}" if ENV['DEBUG']
            blob = create_blob_from_file(image_path, File.basename(image_path))
            if blob
              # Replace the img tag with an action-text-attachment
              attachment_html = create_attachment_html(blob, img['alt'])
              img.replace(attachment_html)
              images_processed += 1
            else
              puts "    Warning: Failed to create blob for: #{src}"
              img.remove
            end
          end
        else
          puts "    Warning: Image not found: #{src} (resolved to: #{image_path})"
          # Remove the image tag if we can't find the file
          img.remove unless @dry_run
        end
      elsif src.start_with?('../') && @skip_images
        # Skip image processing but log what we're skipping
        puts "    Skipping image: #{File.basename(src)}"
        img.remove unless @dry_run
      end
      # For absolute URLs, leave them as-is but log them
      if src.start_with?('http')
        puts "    Info: External image: #{src.truncate(60)}"
      end
    end

    puts "    #{'Would process' if @dry_run} #{images_processed} image#{'s' if images_processed != 1}" if images_processed > 0

    # ...existing code...

    # Convert relative links to entry files
    content_element.css('a').each do |link|
      href = link['href']
      next unless href

      if href.start_with?('../entries/')
        # Convert to a placeholder - you might want to implement cross-referencing later
        entry_name = File.basename(href, '.html')
        link['href'] = "##{entry_name}" # or remove entirely
        link['title'] = "Reference to #{entry_name} (original Dreamwidth entry)"
      end
    end

    # Clean up the HTML a bit
    clean_html(content_element.inner_html)
  end

  def clean_html(html)
    # Remove empty paragraphs and clean up spacing
    html.gsub(/<p[^>]*>\s*<\/p>/, '')
        .gsub(/<br\s*\/?>\s*<br\s*\/?>/, '<br><br>')
        .strip
  end

  def resolve_image_path(relative_src)
    # relative_src is like "../images/2023-06/filename.jpg" or "../userpics/avatar.png"
    # Remove the leading "../"
    cleaned_src = relative_src.sub(/^\.\.\//, '')

    # Check the full path as specified in the HTML
    full_path = File.join(@folder_path, cleaned_src)

    return full_path if File.exist?(full_path)

    # Try some variations in case the structure is different
    # Extract just the filename for fallback searches
    filename = File.basename(cleaned_src)

    alt_paths = [
      File.join(@images_path, filename),
      File.join(@userpics_path, filename)
    ]

    # Also try to find the file in any subdirectory of images
    if cleaned_src.start_with?('images/')
      Dir.glob(File.join(@images_path, '**', filename)).each do |path|
        return path if File.exist?(path)
      end
    end

    alt_paths.each do |path|
      return path if File.exist?(path)
    end

    nil
  end

  def create_blob_from_file(file_path, filename)
    begin
      puts "    DEBUG: create_blob_from_file called with file_path='#{file_path}', filename='#{filename}'" if ENV['DEBUG']

      # Verify the file exists before trying to open it
      unless File.exist?(file_path)
        puts "    ERROR: File does not exist at path: #{file_path}"
        return nil
      end

      puts "    DEBUG: File exists, size=#{File.size(file_path)}" if ENV['DEBUG']

      # Test file access
      begin
        File.open(file_path, 'rb') do |test_file|
          test_file.read(1) # Try to read just 1 byte
        end
        puts "    DEBUG: File is readable" if ENV['DEBUG']
      rescue => e
        puts "    ERROR: Cannot read file #{file_path}: #{e.message}"
        return nil
      end

      # Determine content type using the full file path
      content_type = Marcel::MimeType.for(Pathname.new(file_path))

      # Validate it's an image
      unless content_type.start_with?('image/')
        puts "    Warning: #{filename} is not an image (#{content_type})"
        return nil
      end

      puts "    DEBUG: About to create ActiveStorage blob for #{content_type}" if ENV['DEBUG']

      File.open(file_path, 'rb') do |file|
        ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: filename,
          content_type: content_type
        )
      end
    rescue => e
      puts "    Error creating blob for #{filename}: #{e.message}"
      puts "    File path was: #{file_path}"
      puts "    Error backtrace: #{e.backtrace.first}" if ENV['DEBUG']
      nil
    end
  end

  def create_attachment_html(blob, alt_text = nil)
    # For import scripts, we'll use a simpler attachment format
    # that doesn't require URL generation
    %Q(
      <action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{blob.content_type}"
        filename="#{blob.filename}" filesize="#{blob.byte_size}" previewable="true">
      </action-text-attachment>
    ).strip
  end

  def extract_tags(doc)
    tag_elements = doc.css('.tag ul li a')

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
    tags.first(20)
  end
end

# Usage when run with rails runner:
# rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html blog_subdomain [--dry-run]

def print_usage
  puts "Usage: rails runner #{__FILE__} <path_to_dreamwidth_folder> <blog_subdomain> [--dry-run]"
  puts ""
  puts "Arguments:"
  puts "  path_to_dreamwidth_folder  - Path to the extracted Dreamwidth dump folder"
  puts "  blog_subdomain            - Subdomain of the Pagecord blog to import into"
  puts "  --dry-run                 - Optional: Preview what would be imported without making changes"
  puts ""
  puts "Examples:"
  puts "  rails runner #{__FILE__} /Users/olly/Downloads/dreamwidth-dump-html myblog"
  puts "  rails runner #{__FILE__} /Users/olly/Downloads/dreamwidth-dump-html myblog --dry-run"
  puts "  rails runner #{__FILE__} /Users/olly/Downloads/dreamwidth-dump-html myblog --skip-images"
end

if ARGV.length < 2 || ARGV.length > 4
  print_usage
  exit 1
end

folder_path = ARGV[0]
blog_subdomain = ARGV[1]
dry_run = ARGV.include?('--dry-run')
skip_images = ARGV.include?('--skip-images')

unless Dir.exist?(folder_path)
  puts "Error: Folder not found: #{folder_path}"
  exit 1
end

begin
  importer = DreamwidthImporter.new(folder_path, blog_subdomain, dry_run: dry_run, skip_images: skip_images)
  importer.import!
rescue => e
  puts "Fatal error: #{e.message}"
  puts e.backtrace.first if Rails.env.development?
  exit 1
end
