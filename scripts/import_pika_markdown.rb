require "nokogiri"
require_relative "import_helpers"
require_relative "import_markdown"

# Import a Pika markdown export into Pagecord posts
#
# The export is a directory of posts/, pages/ and images/, where each markdown
# file carries front matter and refers to its images as ../images/<file>.
#
# Usage: bundle exec rails runner scripts/import_pika_markdown.rb path/to/export blog_subdomain [--dry-run]
def import_pika_markdown(export_root, blog_subdomain, dry_run: false)
  include ImportHelpers

  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  check_import_allowed!(blog, dry_run: dry_run)

  unless File.directory?(export_root)
    puts "Export not found: #{export_root}"
    return
  end

  files = Dir.glob(File.join(export_root, "{posts,pages}", "*.md")).sort
  if files.empty?
    puts "No markdown files found under #{export_root}/posts or #{export_root}/pages"
    return
  end

  puts "Found #{files.length} markdown files to import"

  success_count = 0
  failed_count = 0
  skipped_count = 0
  aliased = []

  files.each do |file|
    front_matter, markdown = extract_front_matter(File.read(file))

    title = front_matter["title"].to_s.strip.presence
    slug = pika_slug(front_matter["slug"])
    # Pika serves one page at "/", which is what a Pagecord home page is
    is_home_page = front_matter["slug"].to_s.strip == "/"
    is_page = front_matter["page"].present? && truthy?(front_matter["page"])
    status = front_matter["status"].to_s == "draft" ? :draft : :published
    published_at = parse_datetime(
      front_matter["date"]&.to_s,
      fallback_message: "Warning: Could not parse date for #{File.basename(file)}"
    )

    # Pika keeps the slug a post used to have. Nothing serves those on Pagecord,
    # so they are reported rather than silently dropped.
    aliased << [ front_matter["alias"], slug ] if front_matter["alias"].present?

    label = title || slug || (is_home_page ? "home page" : File.basename(file))

    existing_post = (slug && blog.all_posts.find_by(slug: slug)) || (title && post_exists?(blog, title))
    if existing_post
      puts "Skipping duplicate: #{label}"
      skipped_count += 1
      next
    end

    markdown = normalize_markdown_hard_breaks(markdown)
    markdown = normalize_markdown_footnotes(markdown, id_prefix: slug.presence || File.basename(file, ".md"))
    content_doc = Nokogiri::HTML::DocumentFragment.parse(render_markdown_preserving_dynamic_variables(markdown))

    rewrite_pika_paths(content_doc)

    post = blog.all_posts.new(
      title: title,
      slug: slug,
      published_at: published_at,
      tag_list: parse_markdown_tags(front_matter["tags"]),
      is_page: is_page,
      status: status,
      is_home_page: is_home_page
    )

    puts "Processing: #{label}"

    begin
      post.content = process_images_to_actiontext(content_doc.to_html, assets_root: export_root, dry_run: dry_run)
    rescue => e
      puts "Failed to process images for #{label}: #{e.message}"
      failed_count += 1
      next
    end

    type_label = is_page ? "page" : "post"
    status_label = status == :draft ? " (draft)" : ""

    if dry_run
      puts "[DRY RUN] Would create #{type_label}#{status_label}: #{label}"
      puts "[DRY RUN] Slug: #{post.slug}" if post.slug.present?
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Tags: #{post.tag_list.join(", ")}" if post.tag_list.any?

      if post.valid?
        puts "[DRY RUN] Validation: PASSED"
        success_count += 1
      else
        puts "[DRY RUN] Validation: FAILED"
        puts "[DRY RUN] Errors: #{post.errors.full_messages.join(", ")}"
        failed_count += 1
      end
      next
    end

    if post.save
      blog.update!(home_page_id: post.id) if is_home_page
      puts "Created #{type_label}#{status_label}: #{label} (#{is_home_page ? "the blog home page" : "/#{post.slug}"})"
      success_count += 1
    else
      puts "Failed to create #{type_label}: #{label}"
      puts post.errors.full_messages
      failed_count += 1
    end
  end

  puts "\n=== #{dry_run ? "DRY RUN " : ""}IMPORT SUMMARY ==="
  puts "Imported: #{success_count}"
  puts "Failed: #{failed_count}" if failed_count > 0
  puts "Skipped (duplicates): #{skipped_count}" if skipped_count > 0

  if aliased.any?
    puts "\n#{aliased.size} posts were previously published at a different Pika slug."
    puts "Nothing serves those URLs on Pagecord, so links to them from elsewhere will 404:"
    aliased.first(10).each { |former, slug| puts "  /#{former} -> /#{slug}" }
    puts "  ...and #{aliased.size - 10} more" if aliased.size > 10
  end
  puts "====================="
end

# Pika slugs are paths – "posts/a-walk", "pages/gallery", "/" for the home page.
# Pagecord slugs have no prefix, and /posts/:slug already redirects to /:slug.
def pika_slug(slug)
  trimmed = slug.to_s.strip.delete_prefix("/").delete_suffix("/")
  trimmed = trimmed.split("/", 2).last.to_s if trimmed.start_with?("posts/", "pages/")

  trimmed.presence
end

# Images resolve against the export root once they are rooted, which also lets a
# dry run check every one of them is really there.
def rewrite_pika_paths(content_doc)
  content_doc.css("img[src]").each do |image|
    image["src"] = image["src"].sub(%r{\A(?:\.\./)+}, "/")
  end

  # /posts/:slug redirects, but nothing serves /pages/:slug
  content_doc.css("a[href]").each do |link|
    link["href"] = link["href"].sub(%r{\A/pages/}, "/")
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner scripts/import_pika_markdown.rb path/to/export blog_subdomain [--dry-run]"
    puts ""
    puts "Imports a Pika markdown export – a directory of posts/, pages/ and images/."
    puts ""
    puts "Options:"
    puts "  --dry-run   Preview the import without creating anything"
    puts ""
    puts "Notes:"
    puts "  - Pika's posts/ and pages/ slug prefixes are dropped; /posts/:slug still redirects"
    puts "  - Front matter 'page: true' becomes a Pagecord page"
    puts "  - Images are uploaded from the export's images/ directory"
    puts "  - Titleless posts are supported"
    return
  end

  dry_run = ARGV.include?("--dry-run")
  puts "=== DRY RUN MODE - Nothing will be created ===" if dry_run

  import_pika_markdown(File.expand_path(ARGV[0]), ARGV[1], dry_run: dry_run)
end
