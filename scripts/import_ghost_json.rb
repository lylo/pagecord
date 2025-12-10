require "json"
require "open-uri"
require "nokogiri"
require "cgi"
require_relative "import_helpers"

# Import Ghost JSON export into Pagecord posts
# Usage: ruby import_ghost_json.rb path/to/ghost_export.json blog_subdomain ghost_url [--dry-run] [--as-pages] [--include-pages] [--include-drafts]
def import_ghost_json(file_path, blog_subdomain, ghost_url, dry_run: false, as_pages: false, include_pages: false, include_drafts: false)
  include ImportHelpers

  # Parse the Ghost JSON file
  json_data = JSON.parse(File.read(file_path))

  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  # Extract data from the JSON structure
  posts_data = json_data.dig("db", 0, "data", "posts") || []
  tags_data = json_data.dig("db", 0, "data", "tags") || []
  posts_tags_data = json_data.dig("db", 0, "data", "posts_tags") || []

  # Build tags lookup by id (only public tags, skip internal ones starting with #)
  tags_lookup = {}
  tags_data.each do |tag|
    next if tag["visibility"] == "internal" || tag["name"].to_s.start_with?("#")
    tags_lookup[tag["id"]] = tag["name"]
  end

  # Build post_id -> tag_names mapping
  post_tags_lookup = Hash.new { |h, k| h[k] = [] }
  posts_tags_data.each do |pt|
    tag_name = tags_lookup[pt["tag_id"]]
    post_tags_lookup[pt["post_id"]] << tag_name if tag_name
  end

  # Filter posts based on options
  posts_to_import = posts_data.select do |post|
    type_match = post["type"] == "post" || (include_pages && post["type"] == "page")
    status_match = post["status"] == "published" || (include_drafts && post["status"] == "draft")
    type_match && status_match
  end

  puts "Found #{posts_to_import.length} items to import"
  puts "  (filtering: #{include_pages ? 'posts + pages' : 'posts only'}, #{include_drafts ? 'published + drafts' : 'published only'})"
  puts "All imports will be created as pages (is_page = true)" if as_pages

  success_count = 0
  failed_count = 0
  skipped_count = 0

  posts_to_import.each do |post_data|
    # Extract post attributes from Ghost format
    title = post_data["title"]
    html_content = post_data["html"]
    plaintext_content = post_data["plaintext"]
    published_at_str = post_data["published_at"]
    excerpt = post_data["custom_excerpt"]
    feature_image = post_data["feature_image"]
    ghost_type = post_data["type"]

    puts "Processing: #{title}"

    # Parse published_at
    published_at = parse_datetime(published_at_str, fallback_message: "Warning: Could not parse datetime for #{title}")

    # Extract tags for this post
    tag_list = (post_tags_lookup[post_data["id"]] || []).map { |t| clean_tag(t) }.reject(&:empty?)

    # Determine is_page: use --as-pages flag if provided, otherwise use type from Ghost
    is_page = as_pages || ghost_type == "page"

    # Check if post already exists by title (case-insensitive) or slug
    existing_post = post_exists?(blog, title)
    if existing_post
      puts "Skipping duplicate: #{title} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_count += 1
      next
    end

    # Replace __GHOST_URL__ references with the actual ghost URL
    feature_image = feature_image.gsub("__GHOST_URL__", ghost_url) if feature_image

    # Determine content to use (html -> plaintext -> custom_excerpt)
    content_to_use = nil
    content_needs_feature_image = false

    if html_content.present?
      content_to_use = html_content.gsub("__GHOST_URL__", ghost_url)
    elsif plaintext_content.present?
      content_to_use = Html::PlainTextToHtml.call(plaintext_content)
      content_needs_feature_image = true
    elsif excerpt.present?
      content_to_use = "<p>#{excerpt}</p>"
      content_needs_feature_image = true
    end

    # Add feature image to content if needed
    if content_needs_feature_image && feature_image.present?
      feature_img_tag = "<img src=\"#{feature_image}\" alt=\"#{CGI.escapeHTML(title.to_s)}\" />"
      content_to_use = "#{feature_img_tag}\n#{content_to_use}"
    end

    # Create the Post object (without content yet, so we don't trigger ActionText parsing of <img>)
    post = blog.all_posts.new(
      title: title,
      published_at: published_at,
      tag_list: tag_list,
      is_page: is_page,
      show_in_navigation: false
    )

    # Process images and create ActionText content
    if content_to_use.present?
      begin
        post.content = process_images_to_actiontext(content_to_use, dry_run: dry_run)
      rescue => e
        puts "Skipping post due to image processing failure: #{title} - #{e.message}"
        failed_count += 1
        next
      end
    else
      post.content = ""
    end

    if dry_run
      puts "[DRY RUN] Would create #{is_page ? 'page' : 'post'}: #{title}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Tags: #{tag_list.join(', ')}" if tag_list.any?
      puts "[DRY RUN] Content length: #{post.content.to_plain_text.length} characters"

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
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Total items processed: #{posts_to_import.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped (duplicates): #{skipped_count}"
  puts "====================="
end


# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 3
    puts "Usage: bundle exec rails runner import_ghost_json.rb path/to/ghost_export.json blog_subdomain ghost_url [options]"
    puts ""
    puts "Options:"
    puts "  --dry-run        Preview import without creating posts"
    puts "  --as-pages       Import all items as pages (is_page = true)"
    puts "  --include-pages  Include Ghost pages in import (default: posts only)"
    puts "  --include-drafts Include draft posts (default: published only)"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_ghost_json.rb export.json myblog https://ghost.example.com"
    puts "  bundle exec rails runner scripts/import_ghost_json.rb export.json myblog https://ghost.example.com --dry-run"
    puts "  bundle exec rails runner scripts/import_ghost_json.rb export.json myblog https://ghost.example.com --include-pages --as-pages"
    return
  end

  file_path = ARGV[0]
  blog_subdomain = ARGV[1]
  ghost_url = ARGV[2]
  dry_run = ARGV.include?("--dry-run")
  as_pages = ARGV.include?("--as-pages")
  include_pages = ARGV.include?("--include-pages")
  include_drafts = ARGV.include?("--include-drafts")

  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    return
  end

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_ghost_json(file_path, blog_subdomain, ghost_url,
    dry_run: dry_run,
    as_pages: as_pages,
    include_pages: include_pages,
    include_drafts: include_drafts)
end
