require "open-uri"
require "nokogiri"
require_relative "import_helpers"

# Import posts from an RSS feed URL
# Usage: bundle exec rails runner scripts/import_rss.rb https://example.com/rss.xml blog_subdomain [--dry-run]
def import_rss(feed_url, blog_subdomain, dry_run: false)
  include ImportHelpers

  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}"
    return
  end

  puts "Fetching RSS feed from #{feed_url}"
  xml = URI.open(feed_url, open_timeout: 10, read_timeout: 30).read
  doc = Nokogiri::XML(xml)
  doc.remove_namespaces!

  items = doc.xpath("//item")
  puts "Found #{items.length} items"

  stats = { success: 0, failed: 0, skipped: 0 }

  items.each do |item|
    title = item.at_xpath("title")&.text&.strip
    content = item.at_xpath("encoded")&.text || item.at_xpath("description")&.text
    pub_date = item.at_xpath("pubDate")&.text
    categories = item.xpath("category").map { |c| clean_tag(c.text) }.reject(&:empty?)

    next if content.blank?

    if title.present? && post_exists?(blog, title)
      puts "Skipping duplicate: #{title}"
      stats[:skipped] += 1
      next
    end

    published_at = parse_datetime(pub_date)
    display_title = title.presence || content.truncate(64)
    puts "Processing: #{display_title}"

    post = blog.all_posts.new(
      title: title.presence,
      published_at: published_at,
      tag_list: categories,
      is_page: false,
      show_in_navigation: false
    )

    begin
      post.content = process_images_to_actiontext(content, dry_run: dry_run, skip_on_error: true)
    rescue => e
      puts "  Failed to process content: #{e.message}"
      stats[:failed] += 1
      next
    end

    if dry_run
      puts "[DRY RUN] Would create: #{display_title}"
      stats[:success] += 1 if post.valid?
      stats[:failed] += 1 unless post.valid?
    elsif post.save
      puts "  Created: #{display_title}"
      stats[:success] += 1
    else
      puts "  Failed: #{post.errors.full_messages.join(', ')}"
      stats[:failed] += 1
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Success: #{stats[:success]}"
  puts "Failed: #{stats[:failed]}" if stats[:failed] > 0
  puts "Skipped: #{stats[:skipped]}" if stats[:skipped] > 0
  puts "====================="
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_rss.rb FEED_URL blog_subdomain [--dry-run]"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_rss.rb https://example.com/rss.xml myblog"
    puts "  bundle exec rails runner scripts/import_rss.rb https://example.com/feed myblog --dry-run"
    exit
  end

  feed_url = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?("--dry-run")

  puts "=== DRY RUN MODE ===" if dry_run
  import_rss(feed_url, blog_subdomain, dry_run: dry_run)
end
