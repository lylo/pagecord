require "json"
require "open-uri"
require "nokogiri"
require "cgi"
require_relative "import_helpers"

# Import a Blogmaker JSON export into Pagecord posts
# Usage: ruby import_blogmaker.rb path/to/export.json blog_subdomain [--dry-run] [--include-unlisted] [--skip-images]
def import_blogmaker(path, blog_subdomain, dry_run: false, include_unlisted: false, skip_images: false)
  include ImportHelpers

  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  check_import_allowed!(blog, dry_run: dry_run)

  unless File.file?(path)
    puts "File not found: #{path}"
    return
  end

  puts "Reading Blogmaker export from #{path}"
  data = JSON.parse(File.read(path))

  # Posts and pages share a schema apart from the key prefix
  items = data.fetch("posts", []).map { |post| [ post, "post" ] } +
    data.fetch("pages", []).map { |page| [ page, "page" ] }

  puts "Found #{data.fetch("posts", []).length} posts and #{data.fetch("pages", []).length} pages in Blogmaker export"
  puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved" unless skip_images

  success_count = 0
  failed_count = 0
  skipped_unlisted = 0
  skipped_duplicate = 0
  skipped_empty = 0

  items.each do |item, kind|
    title = item["#{kind}_title"].presence
    is_page = kind == "page"
    # Privacy 1 is public; anything else is unlisted, which is live but left out of the index and sitemap
    is_unlisted = item["#{kind}_privacy"] != "1"
    published_at = Time.at(item["#{kind}_date"].to_i)
    slug = usable_blogmaker_slug(item["#{kind}_url"])
    tag_list = Array(item["post_categories"]).map { |category| clean_tag(category["category_name"].to_s) }.reject(&:empty?).uniq
    display_title = title || slug || "Untitled"

    puts "Processing: #{display_title}"

    if is_unlisted && !include_unlisted
      skipped_unlisted += 1
      next
    end

    existing_post = (slug && blog.all_posts.find_by(slug: slug)) || post_exists?(blog, title)
    if existing_post
      puts "  Skipping duplicate (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_duplicate += 1
      next
    end

    html_content = clean_blogmaker_html(item["#{kind}_text"].to_s,
      feature_image: item["#{kind}_image"],
      feature_alt: item["#{kind}_image_alt"],
      feature_caption: item["#{kind}_image_desc"])

    unless importable_content?(html_content)
      skipped_empty += 1
      next
    end

    post = blog.all_posts.new(
      title: title,
      slug: slug,
      published_at: published_at,
      tag_list: tag_list,
      is_page: is_page,
      hidden: is_unlisted
    )

    post.content = skip_images ? html_content : process_images_to_actiontext(html_content, dry_run: dry_run, skip_on_error: true)

    type_label = is_page ? "page" : "post"
    visibility_label = is_unlisted ? " (hidden)" : ""

    if dry_run
      puts "[DRY RUN] Would create #{type_label}#{visibility_label}: #{display_title}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Slug: #{slug}" if slug
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
      puts "Created #{type_label}#{visibility_label}: #{display_title}"
      success_count += 1
    else
      puts "Failed to create #{type_label}: #{display_title}"
      puts post.errors.full_messages
      failed_count += 1
    end
  end

  skipped_total = skipped_unlisted + skipped_duplicate + skipped_empty

  puts "\n=== IMPORT SUMMARY ==="
  puts "Imported: #{success_count}"
  puts "Failed: #{failed_count}" if failed_count > 0
  if skipped_total > 0
    puts "Skipped: #{skipped_total}"
    puts "  - Unlisted: #{skipped_unlisted}" if skipped_unlisted > 0
    puts "  - Duplicate: #{skipped_duplicate}" if skipped_duplicate > 0
    puts "  - Empty content: #{skipped_empty}" if skipped_empty > 0
  end
  puts "====================="
end

# Keep the Blogmaker URL so existing links and search results still resolve
def usable_blogmaker_slug(url)
  return if url.blank?
  return unless url.match?(/\A[a-z0-9]+([-_][a-z0-9]+)*\z/)
  return if url.length > Sluggable::MAX_SLUG_LENGTH
  return if Sluggable::RESERVED_SLUGS.include?(url)

  url
end

# Blogmaker renders the feature image above the post, so it leads the content here
def clean_blogmaker_html(html, feature_image:, feature_alt:, feature_caption:)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)

  # Bookmark cards become a plain link to the page they preview
  fragment.css(".kg-bookmark-card").each do |card|
    link = card.at_css("a.kg-bookmark-container")
    url = link&.[]("href")
    label = card.at_css(".kg-bookmark-title")&.text&.strip.presence || url
    url ? card.replace("<p><a href=\"#{CGI.escapeHTML(url)}\">#{CGI.escapeHTML(label)}</a></p>") : card.remove
  end

  # Pagecord embeds YouTube and Transistor from bare links; other iframes have no equivalent
  fragment.css("iframe").each do |iframe|
    target = iframe.ancestors("figure").first || iframe
    url = embed_link(iframe["src"].to_s)
    url ? target.replace("<p><a href=\"#{url}\">#{url}</a></p>") : target.remove
  end

  # Tweets keep their quoted text and link; the widget script and figure wrapper are dropped
  fragment.css("style, script").each(&:remove)
  fragment.css("figure").each { |figure| figure.replace(figure.children) if figure.css("img, video").empty? }

  fragment.css("a img").each do |img|
    link = img.ancestors("a").first
    link.replace(img) if link
  end

  fragment.css("img").each do |img|
    img["pagecord"] = "true"
    %w[id data-image style loading class].each { |attribute| img.remove_attribute(attribute) }
  end

  fragment.css("p").each { |paragraph| paragraph.remove if paragraph.text.strip.blank? && paragraph.css("img, video").empty? }

  if feature_image.present?
    caption = feature_caption.present? ? "<figcaption>#{CGI.escapeHTML(feature_caption)}</figcaption>" : ""
    fragment.prepend_child("<figure><img src=\"#{CGI.escapeHTML(feature_image)}\" alt=\"#{CGI.escapeHTML(feature_alt.to_s)}\">#{caption}</figure>")
  end

  Html::LexxyCleaner.clean(Html::Sanitize.new.transform(fragment.to_html))
end

def embed_link(src)
  case src
  when %r{youtube(?:-nocookie)?\.com/embed/([\w-]+)}
    "https://www.youtube.com/watch?v=#{$1}"
  when %r{\Ahttps://share\.transistor\.fm/e/([\w-]+)}
    "https://share.transistor.fm/e/#{$1}"
  end
end

def importable_content?(html)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)
  fragment.text.strip.present? || fragment.css("img, video, action-text-attachment").any?
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_blogmaker.rb path/to/export.json blog_subdomain [options]"
    puts ""
    puts "Imports a Blogmaker JSON export into Pagecord"
    puts ""
    puts "Options:"
    puts "  --dry-run           Preview import without creating posts"
    puts "  --include-unlisted  Import unlisted posts as hidden posts"
    puts "  --skip-images       Don't download images, keep original URLs"
    puts ""
    puts "Notes:"
    puts "  - Blogmaker posts and pages are imported as Pagecord posts and pages"
    puts "  - Blogmaker URLs are kept as slugs, so existing post URLs still work"
    puts "  - Blogmaker categories are imported as Pagecord tags"
    puts "  - Feature images are added to the top of the post content"
    puts "  - YouTube and Transistor embeds become links, which Pagecord embeds on render"
    puts "  - Images will be downloaded if available, otherwise original URLs are preserved"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_blogmaker.rb ./export.json myblog"
    puts "  bundle exec rails runner scripts/import_blogmaker.rb ./export.json myblog --dry-run"
    puts "  bundle exec rails runner scripts/import_blogmaker.rb ./export.json myblog --include-unlisted"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?("--dry-run")
  include_unlisted = ARGV.include?("--include-unlisted")
  skip_images = ARGV.include?("--skip-images")

  puts "=== DRY RUN MODE - No posts will be created ===" if dry_run

  import_blogmaker(path, blog_subdomain, dry_run: dry_run, include_unlisted: include_unlisted, skip_images: skip_images)
end
