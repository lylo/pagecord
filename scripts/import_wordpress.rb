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

def bare_link(url, text = url)
  "<p><a href=\"#{CGI.escapeHTML(url)}\">#{CGI.escapeHTML(text)}</a></p>"
end

# A large site exports as a directory of numbered XML files
def export_files(path)
  File.directory?(path) ? Dir.glob(File.join(path, "*.xml")).sort : [ path ]
end

def read_export(file)
  Nokogiri::XML(File.read(file)).tap(&:remove_namespaces!)
end

# Images in post bodies carry their attachment's ID, which locates the copy WordPress
# made when the site was moved from another host. Attachments and the default
# category can sit in a different file from the posts that use them.
def export_index(files)
  files.each_with_object({ attachments: {} }) do |file, index|
    doc = read_export(file)
    index[:site_host] ||= URI(doc.at_xpath("//channel/link").text.strip).host
    index[:default_category] ||= default_category_nicename(doc)
    doc.xpath("//item[post_type='attachment']").each do |attachment|
      index[:attachments][attachment.at_xpath("post_id").text] = attachment.at_xpath("attachment_url").text.strip
    end
  end
end

# An image on the blog's own host is fetched without the query string that scales it.
# One on another host is usually gone, so its attachment is used.
def media_url(img, index)
  src = img["src"].to_s
  return src.sub(/\?.*/, "") if src[%r{\Ahttps?://([^/?#]+)}, 1] == index[:site_host]

  index[:attachments][img["class"].to_s[/wp-image-(\d+)/, 1] || img["data-id"]] || src
end

def with_featured_image(item, body, index)
  id = item.at_xpath("postmeta[meta_key='_thumbnail_id']/meta_value")&.text
  url = index[:attachments][id]
  return body if url.nil? || body.match?(/wp-image-#{id}\b/) || body.include?(File.basename(url))

  %(<img src="#{CGI.escapeHTML(url)}" class="wp-image-#{id}">\n\n#{body})
end

def gallery_shortcode(attributes, index)
  ids = attributes[/ids="([\d,\s]+)"/, 1].to_s.split(",").map(&:strip)
  urls = index[:attachments].values_at(*ids).compact
  return "".tap { puts "  Warning: dropped [gallery#{attributes}] as it lists no attachments" } if urls.empty?

  %(<figure class="wp-block-gallery">#{urls.map { |url| %(<figure><img src="#{CGI.escapeHTML(url)}"></figure>) }.join}</figure>)
end

def google_maps_link(embed_url)
  embed_url = CGI.unescapeHTML(embed_url)
  longitude, latitude = embed_url.match(/!2d(-?[\d.]+)!3d(-?[\d.]+)/)&.captures
  bare_link(latitude ? "https://www.google.com/maps?q=#{latitude},#{longitude}" : embed_url, "Google Maps")
end

# Every WordPress gallery becomes a figure holding one figure per image, with its
# caption. After sanitising, that nesting is the only way left to recognise one.
def regroup_galleries(fragment)
  while (gallery = fragment.at_css(".wp-block-gallery, .wp-block-jetpack-tiled-gallery, .tiled-gallery, .wp-block-jetpack-slideshow, .wp-block-coblocks-gallery-collage"))
    puts "  Warning: a gallery has no images" if gallery.css("img").empty?
    figures = gallery.css("img").map do |img|
      caption = img.parent.at_css("> figcaption") if img.parent.name == "figure" && img.parent != gallery
      "<figure>#{img.to_html}#{caption&.to_html}</figure>"
    end
    caption = gallery.at_css("> figcaption")
    gallery.replace("<figure>#{figures.join}</figure>#{"<p>#{caption.inner_html}</p>" if caption}")
  end
end

def build_galleries(html)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)
  fragment.css("figure").select { |figure| figure.element_children.any? && figure.element_children.all? { |child| child.name == "figure" } }.each do |figure|
    if figure.element_children.size > 1
      figure.name = "div"
      figure["class"] = "attachment-gallery attachment-gallery--#{figure.element_children.size}"
    else
      figure.replace(figure.children)
    end
  end
  fragment.to_html
end

# Import WordPress WXR exported XML files into Pagecord posts
# Usage: ruby import_wordpress.rb path/to/export.xml blog_subdomain [--dry-run]
def import_wordpress(path, blog_subdomain, dry_run: false, include_private: false, skip_images: false, markdown: false, assets_root: nil, featured_images: false)
  include ImportHelpers

  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  check_import_allowed!(blog, dry_run: dry_run)

  files = export_files(path)
  unless files.any? && files.all? { |file| File.file?(file) && file.end_with?(".xml") }
    puts "No XML export found at #{path}"
    return
  end

  puts "Reading WordPress export from #{files.size} file(s) in #{path}"
  index = export_index(files)
  items = files.lazy.flat_map { |file| read_export(file).xpath("//item").to_a }
  puts "Found #{index[:attachments].size} attachments"
  puts "Using downloaded media from #{assets_root}" if assets_root
  puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved"

  default_category = index[:default_category]

  success_count = 0
  failed_count = 0
  skipped_private = 0
  skipped_protected = 0
  skipped_duplicate = 0
  skipped_empty = 0
  skipped_other = 0

  items.each do |item|
    # Extract post metadata
    title = CGI.unescapeHTML(item.at_xpath("title")&.text&.strip.to_s)
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

    # Drafts have no GMT date until they are published
    post_date_gmt = item.at_xpath("post_date_gmt")&.text&.strip.to_s
    published_at = post_date_gmt.match?(/\A[1-9]/) ? Time.find_zone("UTC").parse(post_date_gmt) : parse_datetime(post_date, fallback_message: "Warning: Could not parse datetime '#{post_date}' for '#{title}'")

    # Extract categories AND tags as tag list, dropping the category WordPress
    # assigns by default: it sits on every post, so it says nothing about any of them
    categories = item.xpath("category[@domain='category']")
      .reject { |cat| cat["nicename"] == default_category }
      .map { |cat| CGI.unescapeHTML(cat.text.strip) }
    post_tags = item.xpath("category[@domain='post_tag']").map { |tag| CGI.unescapeHTML(tag.text.strip) }
    tag_list = (categories + post_tags)
      .reject { |t| t.downcase == "uncategorized" }
      .uniq
      .map { |t| clean_tag(t) }
      .reject(&:empty?)

    # Determine is_page from WordPress post_type
    is_page = post_type == "page"

    # Keep the WordPress URL so existing links and search results still resolve
    slug = usable_slug(item.at_xpath("post_name")&.text&.strip)

    # A WordPress slug is unique, so posts sharing a title are only compared by title when they have none
    existing_post = if slug
      blog.all_posts.find_by(slug: slug)
    else
      title.present? ? post_exists?(blog, title) : blog.all_posts.find_by(title: nil, published_at: published_at)
    end

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

    content_encoded = with_featured_image(item, content_encoded, index) if featured_images
    body = content_encoded.gsub("\r", "")
    cleaned_content = markdown ? Post::Markdown.render(body).last : wrap_paragraphs(body)

    content_doc = Nokogiri::HTML::DocumentFragment.parse(cleaned_content)

    content_doc.css("style, script").each(&:remove)

    # Iframe embeds become bare links, which Pagecord embeds where it supports the site
    content_doc.css("iframe").each do |iframe|
      src = iframe["src"].to_s

      url = case src
      when %r{youtube(?:-nocookie)?\.com/embed/([a-zA-Z0-9_-]+)}
        "https://www.youtube.com/watch?v=#{$1}"
      when %r{player\.vimeo\.com/video/(\d+)}
        "https://vimeo.com/#{$1}"
      when %r{facebook\.com/plugins/}
        URI.decode_www_form(URI(src).query.to_s).to_h["href"]
      else
        src.presence
      end

      url ? iframe.replace(bare_link(url)) : iframe.remove
    end

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

      obj.replace(bare_link(url)) if url
    end

    # WordPress embeds a URL that sits alone on a line, and so does Pagecord when it is a bare link
    content_doc.css("p").each do |paragraph|
      url = paragraph.text.strip
      paragraph.replace(bare_link(url)) if paragraph.element_children.empty? && url.match?(%r{\Ahttps?://\S+\z})
    end
    content_doc.css(".wp-block-embed figcaption").each { |caption| caption.name = "p" }
    content_doc.css(".wp-block-embed, .wp-block-embed__wrapper").each { |embed| embed.replace(embed.children) }

    # Unwrap images from <a> tags (WordPress often links images to full-size versions)
    content_doc.css("a:has(img)").each { |link| link.replace(link.children) }

    # A [gallery] without ids shows the post's attachments, which the export doesn't link back to the post
    html_content = content_doc.to_html
      .gsub(%r{(?:<p>\s*)?\[gallery([^\]]*)\](?:\s*</p>)?}) { gallery_shortcode($1, index) }
      .gsub(%r{\[embed[^\]]*\](.*?)\[/embed\]|\[youtube[= ]([^\]\s]+)[^\]]*\]}) { bare_link(CGI.unescapeHTML($1 || $2)) }
      .gsub(%r{(?:<p>\s*)?\[googlemaps\s+([^\s\]]+)[^\]]*\](?:\s*</p>)?}) { google_maps_link($1) }

    # Handle WordPress caption shortcodes [caption]...[/caption]
    # Extract the content and convert to figure/figcaption
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
    regroup_galleries(content_doc)

    # Mark images with pagecord="true" so they survive sanitization
    content_doc.css("img").each do |img|
      img["src"] = media_url(img, index)
      img["pagecord"] = "true"
    end

    sanitized_content = build_galleries(Html::Sanitize.new.transform(content_doc.to_html))

    post.content = skip_images ? sanitized_content : process_images_to_actiontext(sanitized_content, assets_root: assets_root, dry_run: dry_run, skip_on_error: true)

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
    end
  rescue => error
    puts "Failed on #{item.at_xpath("title")&.text}: #{error.class}: #{error.message}"
    failed_count += 1
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
    puts "Usage: bundle exec rails runner scripts/import_wordpress.rb path/to/export.xml_or_directory blog_subdomain [options]"
    puts ""
    puts "Imports WordPress WXR export files into Pagecord"
    puts ""
    puts "Options:"
    puts "  --dry-run          Preview import without creating posts"
    puts "  --include-private  Import private posts as hidden posts"
    puts "  --skip-images      Don't download images, keep original URLs"
    puts "  --markdown         Post bodies are Markdown, as in Micro.blog exports"
    puts "  --featured-images  Open each post with its featured image, unless the body already shows it"
    puts "  --assets-root=DIR  Read images from DIR/<host>/<path> when there, rather than fetching them"
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
    puts "  bundle exec rails runner scripts/import_wordpress.rb ./export-dir myblog --assets-root=./media"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?('--dry-run')
  include_private = ARGV.include?('--include-private')
  skip_images = ARGV.include?('--skip-images')
  markdown = ARGV.include?('--markdown')
  featured_images = ARGV.include?("--featured-images")
  assets_root = ARGV.find { |arg| arg.start_with?("--assets-root=") }&.split("=", 2)&.last&.then { |dir| File.expand_path(dir) }

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_wordpress(path, blog_subdomain, dry_run: dry_run, include_private: include_private, skip_images: skip_images, markdown: markdown, assets_root: assets_root, featured_images: featured_images)
end
