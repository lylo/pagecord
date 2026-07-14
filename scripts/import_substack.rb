require "csv"
require "cgi"
require "json"
require "nokogiri"
require_relative "import_helpers"

# Import Substack exports into Pagecord posts.
# Usage: ruby import_substack.rb path/to/substack_export blog_subdomain [--dry-run] [--include-drafts] [--include-private] [--include-subscribers] [--skip-images]
def import_substack(path, blog_subdomain, dry_run: false, include_drafts: false, include_private: false, include_subscribers: false, skip_images: false)
  include ImportHelpers

  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  export_root = File.expand_path(path)
  posts_csv_path = File.join(export_root, "posts.csv")
  posts_dir = File.join(export_root, "posts")

  unless File.directory?(export_root)
    puts "Directory not found: #{export_root}"
    return
  end

  unless File.file?(posts_csv_path)
    puts "Substack posts CSV not found: #{posts_csv_path}"
    return
  end

  unless File.directory?(posts_dir)
    puts "Substack posts directory not found: #{posts_dir}"
    return
  end

  rows = CSV.read(posts_csv_path, headers: true)
  puts "Found #{rows.length} posts in Substack export"
  puts "Note: Images will be downloaded if available, otherwise original URLs will be preserved" unless skip_images
  puts "Note: Substack gallery captions are imported as italic paragraphs after galleries; Pagecord only supports captions on single images."

  success_count = 0
  failed_count = 0
  skipped_duplicate = 0
  skipped_draft = 0
  skipped_private = 0
  skipped_missing_html = 0
  skipped_empty = 0

  rows.each do |row|
    post_id = row["post_id"].to_s
    title = row["title"].presence
    subtitle = row["subtitle"].presence
    published_at = parse_datetime(row["post_date"], fallback_message: "Warning: Could not parse datetime for #{title || post_id}")
    is_published = truthy?(row["is_published"])
    is_private = row["audience"].present? && row["audience"] != "everyone"
    slug = post_id.split(".", 2).second
    html_path = File.join(posts_dir, "#{post_id}.html")
    display_title = title.presence || slug.presence || post_id

    puts "Processing: #{display_title}"

    unless is_published || include_drafts
      skipped_draft += 1
      next
    end

    if is_private && !include_private
      skipped_private += 1
      next
    end

    unless File.file?(html_path)
      puts "  Skipping, HTML file not found: #{html_path}"
      skipped_missing_html += 1
      next
    end

    existing_post = post_exists?(blog, title) || post_exists_by_slug(blog, slug)
    if existing_post
      puts "  Skipping duplicate (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_duplicate += 1
      next
    end

    html_content = clean_substack_html(File.read(html_path), subtitle: subtitle)
    unless importable_content?(html_content)
      skipped_empty += 1
      next
    end

    post = blog.all_posts.new(
      title: title,
      slug: slug,
      published_at: published_at,
      is_page: false,
      status: is_published ? :published : :draft,
      hidden: is_private
    )

    post.content = skip_images ? html_content : process_images_to_actiontext(html_content, dry_run: dry_run, skip_on_error: true)

    if dry_run
      status_label = is_published ? "" : " (draft)"
      visibility_label = is_private ? " (hidden)" : ""
      puts "[DRY RUN] Would create post#{status_label}#{visibility_label}: #{display_title}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Slug: #{slug}" if slug.present?
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
      puts "Created post: #{display_title}"
      success_count += 1
    else
      puts "Failed to create post: #{display_title}"
      puts post.errors.full_messages
      failed_count += 1
    end
  end

  subscriber_counts = include_subscribers ? import_substack_subscribers(export_root, blog, dry_run: dry_run) : nil
  skipped_total = skipped_duplicate + skipped_draft + skipped_private + skipped_missing_html + skipped_empty

  puts "\n=== IMPORT SUMMARY ==="
  puts "Posts imported: #{success_count}"
  puts "Posts failed: #{failed_count}" if failed_count > 0
  if skipped_total > 0
    puts "Posts skipped: #{skipped_total}"
    puts "  - Duplicate: #{skipped_duplicate}" if skipped_duplicate > 0
    puts "  - Draft: #{skipped_draft}" if skipped_draft > 0
    puts "  - Private/restricted audience: #{skipped_private}" if skipped_private > 0
    puts "  - Missing HTML: #{skipped_missing_html}" if skipped_missing_html > 0
    puts "  - Empty content: #{skipped_empty}" if skipped_empty > 0
  end
  if subscriber_counts
    puts "Subscribers imported: #{subscriber_counts[:imported]}"
    puts "Subscribers failed: #{subscriber_counts[:failed]}" if subscriber_counts[:failed] > 0
    puts "Subscribers skipped: #{subscriber_counts[:skipped]}" if subscriber_counts[:skipped] > 0
  end
  puts "====================="
end

def clean_substack_html(html, subtitle:)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)
  galleries = extract_substack_galleries(fragment)

  fragment.css("style, script, iframe, .subscription-widget-wrap-editor, .subscription-widget, .image-link-expand").each(&:remove)
  fragment.css(".button-wrapper").each(&:remove)

  fragment.css("a img").each do |img|
    link = img.ancestors("a").first
    link.replace(img) if link
  end

  fragment.css("img").each do |img|
    img["pagecord"] = "true"
    img.remove_attribute("srcset")
    img.remove_attribute("sizes")
    img.remove_attribute("data-attrs")
    img.remove_attribute("fetchpriority")
  end

  fragment.css("source, svg").each(&:remove)
  fragment.css("p").each { |paragraph| paragraph.remove if paragraph.text.strip.blank? && paragraph.css("img, video").empty? }

  sanitized_content = restore_substack_galleries(Html::LexxyCleaner.clean(Html::Sanitize.new.transform(fragment.to_html)), galleries)
  return Html::LexxyCleaner.clean(sanitized_content) unless subtitle.present?

  Html::LexxyCleaner.clean("<p><em>#{CGI.escapeHTML(subtitle)}</em></p>\n#{sanitized_content}")
end

def extract_substack_galleries(fragment)
  galleries = {}

  fragment.css(".image-gallery-embed").each_with_index do |gallery_node, index|
    token = "PAGECORDSUBSTACKGALLERY#{index}TOKEN"
    data = JSON.parse(gallery_node["data-attrs"].to_s)
    gallery = data["gallery"] || {}
    images = Array(gallery["images"]).filter_map { |image| image["src"].presence }

    if images.any?
      galleries[token] = substack_gallery_html(images, caption: gallery["caption"], alt: gallery["alt"])
      gallery_node.replace(token)
    else
      gallery_node.remove
    end
  rescue JSON::ParserError
    gallery_node.remove
  end

  galleries
end

def substack_gallery_html(images, caption:, alt:)
  image_tags = images.map do |src|
    %(<img src="#{CGI.escapeHTML(src)}" alt="#{CGI.escapeHTML(alt.to_s)}" pagecord="true">)
  end.join

  return %(<figure>#{image_tags}<figcaption>#{CGI.escapeHTML(caption.to_s)}</figcaption></figure>) if images.one?

  gallery = %(<div class="attachment-gallery attachment-gallery--#{images.length}">#{image_tags}</div>)
  return gallery if caption.blank?

  %(#{gallery}<p><em>#{CGI.escapeHTML(caption)}</em></p>)
end

def restore_substack_galleries(html, galleries)
  galleries.each do |token, gallery_html|
    html = html.gsub(/<p>\s*#{Regexp.escape(token)}\s*<\/p>/, gallery_html)
    html = html.gsub(token, gallery_html)
  end

  html
end

def import_substack_subscribers(export_root, blog, dry_run:)
  subscribers_csv_path = Dir[File.join(export_root, "email_list*.csv")].first
  unless subscribers_csv_path
    puts "Subscriber CSV not found, skipping subscribers"
    return { imported: 0, failed: 0, skipped: 0 }
  end

  rows = CSV.read(subscribers_csv_path, headers: true)
  puts "\nFound #{rows.length} subscribers in Substack export"

  imported_count = 0
  failed_count = 0
  skipped_count = 0

  rows.each do |row|
    email = row["email"].to_s.strip.downcase
    next if email.blank?

    if truthy?(row["email_disabled"])
      skipped_count += 1
      next
    end

    if blog.email_subscribers.where("LOWER(email) = LOWER(?)", email).exists?
      skipped_count += 1
      next
    end

    subscribed_at = parse_datetime(row["created_at"])
    subscriber = blog.email_subscribers.new(
      email: email,
      confirmed_at: subscribed_at,
      created_at: subscribed_at,
      updated_at: Time.current
    )

    if dry_run
      if subscriber.valid?
        imported_count += 1
      else
        puts "[DRY RUN] Subscriber validation failed for #{email}: #{subscriber.errors.full_messages.join(", ")}"
        failed_count += 1
      end
    elsif subscriber.save
      imported_count += 1
    else
      puts "Failed to import subscriber #{email}: #{subscriber.errors.full_messages.join(", ")}"
      failed_count += 1
    end
  end

  { imported: imported_count, failed: failed_count, skipped: skipped_count }
end

def post_exists_by_slug(blog, slug)
  return false if slug.blank?

  blog.all_posts.find_by(slug: slug)
end

def truthy?(value)
  ActiveModel::Type::Boolean.new.cast(value)
end

def importable_content?(html)
  fragment = Nokogiri::HTML::DocumentFragment.parse(html)
  fragment.text.strip.present? || fragment.css("img, video, action-text-attachment").any?
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_substack.rb path/to/substack_export blog_subdomain [options]"
    puts ""
    puts "Imports Substack export directories into Pagecord"
    puts ""
    puts "Options:"
    puts "  --dry-run              Preview import without creating records"
    puts "  --include-drafts       Import unpublished Substack posts as drafts"
    puts "  --include-private      Import restricted-audience posts as hidden posts"
    puts "  --include-subscribers  Import email subscribers with email_disabled=false as confirmed subscribers"
    puts "  --skip-images          Don't download images, keep original URLs"
    puts ""
    puts "Examples:"
    puts "  bundle exec rails runner scripts/import_substack.rb ./substack_export myblog"
    puts "  bundle exec rails runner scripts/import_substack.rb ./substack_export myblog --dry-run"
    puts "  bundle exec rails runner scripts/import_substack.rb ./substack_export myblog --include-subscribers"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]
  dry_run = ARGV.include?("--dry-run")
  include_drafts = ARGV.include?("--include-drafts")
  include_private = ARGV.include?("--include-private")
  include_subscribers = ARGV.include?("--include-subscribers")
  skip_images = ARGV.include?("--skip-images")

  puts "=== DRY RUN MODE - No records will be created ===" if dry_run

  import_substack(path, blog_subdomain,
    dry_run: dry_run,
    include_drafts: include_drafts,
    include_private: include_private,
    include_subscribers: include_subscribers,
    skip_images: skip_images)
end
