require "open-uri"
require "nokogiri"
require "cgi"
require_relative "import_helpers"

INLINE_TAGS = %w[a abbr b br cite code del em i img ins kbd mark q s small span strong sub sup u var].freeze

# Containers whose own contents WordPress paragraph-wraps in turn. Everything else
# is still descended into, but its text is left bare: a list item or heading must
# not have its contents lifted into a paragraph of its own.
PARAGRAPH_CONTAINER_TAGS = %w[blockquote div].freeze

# Whitespace here is content, so it is the one element left exactly as it is.
PREFORMATTED_TAG = "pre".freeze

# WordPress stores post bodies with blank lines rather than <p> tags and applies
# wpautop when rendering, so an importer has to do the same job: runs of text
# become paragraphs, and block elements are left alone rather than padded with <br>.
def wrap_paragraphs(html)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)

  # Paragraphs are rebuilt from scratch rather than kept: WordPress bodies use <p>
  # loosely, and one left open across several blank-line-separated paragraphs would
  # otherwise swallow all of them.
  fragment.css("p").to_a.each { |paragraph| paragraph.replace("\n\n#{paragraph.inner_html}\n\n") }

  paragraphize(fragment)
  fragment.to_html
end

def paragraphize(container, wrap: true)
  run = []

  (container.children.to_a + [ nil ]).each do |node|
    if node && (node.text? || INLINE_TAGS.include?(node.name))
      run << node
      next
    end

    flush_paragraphs(run, wrap: wrap)
    next unless node && node.name != PREFORMATTED_TAG

    paragraphize(node, wrap: PARAGRAPH_CONTAINER_TAGS.include?(node.name))
  end
end

def flush_paragraphs(run, wrap:)
  return if run.empty?

  paragraphs = run.map(&:to_html).join
    .split(/\n[[:blank:]]*\n/)
    .map { |paragraph| paragraph.gsub("\n", "<br>").gsub(%r{\A(?:\s*<br\s*/?>)+|(?:<br\s*/?>\s*)+\z}i, "").strip }
    .reject(&:empty?)

  if paragraphs.any?
    run.first.before(wrap ? paragraphs.map { |paragraph| "<p>#{paragraph}</p>" }.join : paragraphs.join("<br><br>"))
  end

  run.each(&:remove)
  run.clear
end

# WordPress assigns every uncategorised post to one category, so whatever it has been
# renamed to carries no meaning. It is always term 1.
def default_category_nicename(doc)
  doc.xpath("//channel/category").find { |category| category.at_xpath("term_id")&.text&.strip == "1" }
    &.at_xpath("category_nicename")&.text&.strip
end

# A WordPress slug is only worth keeping if Pagecord can store it as-is; anything
# else falls back to one derived from the title.
def usable_slug(post_name)
  return if post_name.blank?
  return unless post_name.match?(/\A[a-z0-9]+([-_][a-z0-9]+)*\z/)
  return if post_name.length > Sluggable::MAX_SLUG_LENGTH
  return if Sluggable::RESERVED_SLUGS.include?(post_name)

  post_name
end

# Import WordPress WXR exported XML files into Pagecord posts
# Usage: ruby import_wordpress.rb path/to/export.xml blog_subdomain [--dry-run]
def import_wordpress(path, blog_subdomain, dry_run: false, include_private: false, skip_images: false)
  include ImportHelpers

  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  check_import_allowed!(blog)

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
  puts "Found #{items.length} total items in WordPress export"
  puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved"

  default_category = default_category_nicename(doc)

  success_count = 0
  failed_count = 0
  skipped_private = 0
  skipped_protected = 0
  skipped_duplicate = 0
  skipped_empty = 0
  skipped_other = 0

  items.each do |item|
    # Extract post metadata
    title = item.at_xpath("title")&.text&.strip
    content_encoded = item.at_xpath("encoded")&.text&.strip
    post_date = item.at_xpath("post_date")&.text&.strip
    post_status = item.at_xpath("status")&.text&.strip
    post_type = item.at_xpath("post_type")&.text&.strip
    post_password = item.at_xpath("post_password")&.text&.strip

    # Skip non-post types (attachments, nav_menu_item, etc.)
    next unless post_type == "post" || post_type == "page"

    # Skip password-protected posts (WordPress visibility)
    if post_password.present?
      skipped_protected += 1
      next
    end

    is_published = post_status == "publish"
    is_draft = %w[draft pending].include?(post_status)
    is_private = post_status == "private"

    # Skip private posts unless --include-private is set
    if is_private && !include_private
      skipped_private += 1
      next
    end

    # Skip other statuses (trash, auto-draft, inherit, etc.)
    unless is_published || is_draft || is_private
      skipped_other += 1
      next
    end

    # Parse publication date
    published_at = parse_datetime(post_date, fallback_message: "Warning: Could not parse datetime '#{post_date}' for '#{title}'")

    # Extract categories AND tags as tag list, dropping the category WordPress
    # assigns by default: it sits on every post, so it says nothing about any of them
    categories = item.xpath("category[@domain='category']")
      .reject { |cat| cat["nicename"] == default_category }
      .map { |cat| cat.text.strip }
    post_tags = item.xpath("category[@domain='post_tag']").map { |tag| tag.text.strip }
    tag_list = (categories + post_tags)
      .reject { |t| t.downcase == "uncategorized" }
      .uniq
      .map { |t| clean_tag(t) }
      .reject(&:empty?)

    # Determine is_page from WordPress post_type
    is_page = post_type == "page"

    # Keep the WordPress URL so existing links and search results still resolve
    slug = usable_slug(item.at_xpath("post_name")&.text&.strip)

    # Check if post already exists by slug, or by title (case-insensitive)
    existing_post = slug ? blog.all_posts.find_by(slug: slug) : nil
    existing_post ||= post_exists?(blog, title) if title.present?

    if existing_post
      skipped_duplicate += 1
      next
    end

    # Skip if no content
    if content_encoded.nil? || content_encoded.empty?
      skipped_empty += 1
      next
    end

    # Create the Post object (without content yet, so we don't trigger ActionText parsing of <img>)
    post = blog.all_posts.new(
      title: title.presence,  # nil if empty, Pagecord handles titleless posts
      slug: slug,
      published_at: published_at,
      tag_list: tag_list,
      is_page: is_page,
      status: is_draft ? :draft : :published,
      hidden: is_private
    )

    # Parse and clean HTML content
    cleaned_content = wrap_paragraphs(content_encoded.gsub("\r", ""))

    content_doc = Nokogiri::HTML::DocumentFragment.parse(cleaned_content)

    # Remove style, script, and iframe tags
    content_doc.css("style, script, iframe").each(&:remove)

    # Convert old Flash <object> embeds to plain URLs (Vimeo, YouTube)
    content_doc.css("object").each do |obj|
      embed_src = obj.at_css("embed")&.[]("src") || obj.at_css("param[name='movie']")&.[]("value")
      next unless embed_src

      url = case embed_src
      when /vimeo\.com.*clip_id=(\d+)/
        "https://vimeo.com/#{$1}"
      when /youtube\.com\/v\/([a-zA-Z0-9_-]+)/
        "https://www.youtube.com/watch?v=#{$1}"
      end

      obj.replace("<p>#{url}</p>") if url
    end

    # Unwrap images from <a> tags (WordPress often links images to full-size versions)
    content_doc.css("a img").each do |img|
      link = img.parent
      link.replace(img) if link.name == "a" && link.parent
    end

    # Handle WordPress gallery shortcodes [gallery ids="1,2,3"]
    # These are often left as plain text after export - we'll just remove them
    content_doc.to_html.gsub!(/\[gallery[^\]]*\]/, '')

    # Handle WordPress caption shortcodes [caption]...[/caption]
    # Extract the content and convert to figure/figcaption
    html_content = content_doc.to_html
    html_content = html_content.gsub(/\[caption[^\]]*\](.*?)\[\/caption\]/m) do |_match|
      inner = $1
      inner_doc = Nokogiri::HTML::DocumentFragment.parse(inner)
      img = inner_doc.at_css("img")
      if img
        caption_text = inner_doc.text.strip.gsub(img.text, '').strip
        if caption_text.present?
          "<figure>#{img.to_html}<figcaption>#{CGI.escapeHTML(caption_text)}</figcaption></figure>"
        else
          img.to_html
        end
      else
        inner
      end
    end

    # Re-parse after shortcode processing
    content_doc = Nokogiri::HTML::DocumentFragment.parse(html_content)

    # Mark images with pagecord="true" so they survive sanitization
    content_doc.css("img").each { |img| img["pagecord"] = "true" }

    # Sanitize HTML content (removes style attributes, etc.)
    sanitized_content = Html::Sanitize.new.transform(content_doc.to_html)

    # Process images (download and convert to ActionText attachments)
    post.content = skip_images ? sanitized_content : process_images_to_actiontext(sanitized_content, dry_run: dry_run, skip_on_error: true)

    display_title = title.presence || post.content.to_plain_text.truncate(64) || "Untitled"

    puts "Processing: #{display_title}"

    if dry_run
      type_label = is_page ? "page" : "post"
      status_label = is_draft ? " (draft)" : (is_private ? " (hidden)" : "")
      puts "[DRY RUN] Would create #{type_label}#{status_label}: #{display_title}"
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

    type_label = is_page ? "page" : "post"
    status_label = is_draft ? " (draft)" : (is_private ? " (hidden)" : "")
    if post.save
      puts "Created #{type_label}#{status_label}: #{display_title}"
      success_count += 1
    else
      puts "Failed to create #{type_label}: #{display_title}"
      puts post.errors.full_messages
      failed_count += 1
      next
    end
  end

  skipped_total = skipped_private + skipped_protected + skipped_duplicate + skipped_empty + skipped_other

  puts "\n=== IMPORT SUMMARY ==="
  puts "Imported: #{success_count}"
  puts "Failed: #{failed_count}" if failed_count > 0
  if skipped_total > 0
    puts "Skipped: #{skipped_total}"
    puts "  - Private: #{skipped_private}" if skipped_private > 0
    puts "  - Password-protected: #{skipped_protected}" if skipped_protected > 0
    puts "  - Duplicate: #{skipped_duplicate}" if skipped_duplicate > 0
    puts "  - Empty content: #{skipped_empty}" if skipped_empty > 0
    puts "  - Other status: #{skipped_other}" if skipped_other > 0
  end
  puts "====================="
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_wordpress.rb path/to/export.xml blog_subdomain [options]"
    puts ""
    puts "Imports WordPress WXR export files into Pagecord"
    puts ""
    puts "Options:"
    puts "  --dry-run          Preview import without creating posts"
    puts "  --include-private  Import private posts as hidden posts"
    puts "  --skip-images      Don't download images, keep original URLs"
    puts ""
    puts "Notes:"
    puts "  - Post type (post vs page) is determined from the WordPress export"
    puts "  - WordPress slugs are kept, so existing post URLs still work"
    puts "  - Both categories and tags from WordPress are imported as Pagecord tags,"
    puts "    apart from the default category WordPress puts on every post"
    puts "  - Draft posts are imported as drafts"
    puts "  - Password-protected posts are always skipped"
    puts "  - Titleless posts are supported"
    puts "  - Images will be downloaded if available, otherwise original URLs are preserved"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_wordpress.rb ./export.xml myblog"
    puts "  bundle exec rails runner scripts/import_wordpress.rb ./export.xml myblog --dry-run"
    puts "  bundle exec rails runner scripts/import_wordpress.rb ./export.xml myblog --include-private"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?('--dry-run')
  include_private = ARGV.include?('--include-private')
  skip_images = ARGV.include?('--skip-images')

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_wordpress(path, blog_subdomain, dry_run: dry_run, include_private: include_private, skip_images: skip_images)
end
