require "open-uri"
require "json"
require "nokogiri"
require_relative "import_helpers"

# Import a Wix blog into Pagecord by scraping it – Wix has no post export.
# Usage: ruby import_wix.rb https://www.example.com blog_subdomain [--dry-run] [--skip-images]
def import_wix(site_url, blog_subdomain, dry_run: false, skip_images: false)
  include ImportHelpers

  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  check_import_allowed!(blog, dry_run: dry_run)

  post_urls = wix_post_urls(site_url)
  if post_urls.empty?
    puts "No posts found in #{site_url.chomp("/")}/blog-posts-sitemap.xml"
    return
  end

  puts "Found #{post_urls.length} posts on #{site_url}"

  success_count = 0
  failed_count = 0
  skipped_duplicate = 0
  skipped_empty = 0

  post_urls.each do |url|
    slug = URI.parse(url).path.split("/").last
    document = Nokogiri::HTML(fetch(url))
    title = wix_title(document)
    published_at = parse_datetime(wix_published_at(document), fallback_message: "Warning: Could not parse datetime for #{title || slug}")

    puts "Processing: #{title || slug}"

    existing_post = post_exists?(blog, title) || blog.all_posts.find_by(slug: slug)
    if existing_post
      puts "  Skipping duplicate (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_duplicate += 1
      next
    end

    html_content = clean_wix_html(document)
    if html_content.blank?
      puts "  Skipping, no importable content"
      skipped_empty += 1
      next
    end

    post = blog.all_posts.new(title: title, slug: slug, published_at: published_at, is_page: false, status: :published)
    post.content = skip_images ? html_content : process_images_to_actiontext(html_content, dry_run: dry_run, skip_on_error: true)

    if dry_run
      puts "[DRY RUN] Would create post: #{title}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Slug: #{slug}"
      puts "[DRY RUN] Content length: #{post.content.to_plain_text.length} characters"

      if post.valid?
        puts "[DRY RUN] Post validation: PASSED"
        success_count += 1
      else
        puts "[DRY RUN] Post validation: FAILED"
        puts "[DRY RUN] Errors: #{post.errors.full_messages.join(", ")}"
        failed_count += 1
      end
      next
    end

    if post.save
      puts "Created post: #{title}"
      success_count += 1
    else
      puts "Failed to create post: #{title}"
      puts post.errors.full_messages
      failed_count += 1
    end
  end

  skipped_total = skipped_duplicate + skipped_empty

  puts "\n=== IMPORT SUMMARY ==="
  puts "Posts imported: #{success_count}"
  puts "Posts failed: #{failed_count}" if failed_count > 0
  if skipped_total > 0
    puts "Posts skipped: #{skipped_total}"
    puts "  - Duplicate: #{skipped_duplicate}" if skipped_duplicate > 0
    puts "  - Empty content: #{skipped_empty}" if skipped_empty > 0
  end
  puts "====================="
end

def wix_post_urls(site_url)
  sitemap = Nokogiri::XML(fetch("#{site_url.chomp("/")}/blog-posts-sitemap.xml"))
  sitemap.css("url > loc").map { |loc| loc.text.strip }
rescue OpenURI::HTTPError
  []
end

def wix_title(document)
  document.at_css("[data-hook='post-title']")&.text&.strip.presence ||
    document.at_css("meta[property='og:title']")&.[]("content")&.strip
end

def wix_published_at(document)
  document.css("script[type='application/ld+json']").each do |script|
    data = JSON.parse(script.text) rescue next
    Array.wrap(data).each do |entry|
      return entry["datePublished"] if entry.is_a?(Hash) && entry["datePublished"].present?
    end
  end
  nil
end

# Wix renders the whole post body server side, but every image src is a blurred
# low quality placeholder and videos are React player shells.
def clean_wix_html(document)
  body = document.at_css("[data-hook='post-description']")
  return "" unless body

  fragment = Nokogiri::HTML::DocumentFragment.parse(body.inner_html)

  fragment.css("figure[data-hook='figure-VIDEO']").each do |figure|
    video_url = wix_video_url(figure)
    if video_url
      figure.replace(%(<p><a href="#{video_url}">#{video_url}</a></p>))
    else
      puts "  Warning: dropping an unrecognised video embed"
      figure.remove
    end
  end

  fragment.css("img").each do |img|
    img["src"] = wix_original_image_url(img["src"])
    img["pagecord"] = "true"
    img.remove_attribute("srcset")
    img.remove_attribute("sizes")
  end

  fragment.css("wow-image, span, a u").each { |node| node.replace(node.children) }
  fragment.css("button, svg, script, style, noscript").each(&:remove)
  fragment.css("[id]").each { |node| node.remove_attribute("id") }

  Html::LexxyCleaner.clean(Html::Sanitize.new.transform(fragment.to_html))
end

# https://static.wixstatic.com/media/abc~mv2.jpg/v1/fill/w_147,blur_2/abc~mv2.jpg -> the original
def wix_original_image_url(src)
  src.to_s.sub(%r{/v1/.*\z}, "")
end

def wix_video_url(figure)
  youtube_id = figure.to_html[%r{i\.ytimg\.com/vi/([\w-]+)/}, 1]
  "https://www.youtube.com/watch?v=#{youtube_id}" if youtube_id
end

def fetch(url)
  URI.open(url, open_timeout: 10, read_timeout: 30).read
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_wix.rb https://www.example.com blog_subdomain [options]"
    puts ""
    puts "Scrapes a Wix blog into Pagecord – Wix offers no post export"
    puts ""
    puts "Options:"
    puts "  --dry-run      Preview import without creating records"
    puts "  --skip-images  Don't download images, keep original URLs"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_wix.rb https://www.jeremyet.com myblog --dry-run"
    puts "  bundle exec rails runner scripts/import_wix.rb https://www.jeremyet.com myblog"
    return
  end

  site_url = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?("--dry-run")
  skip_images = ARGV.include?("--skip-images")

  puts "=== DRY RUN MODE - No records will be created ===" if dry_run

  import_wix(site_url, blog_subdomain, dry_run: dry_run, skip_images: skip_images)
end
