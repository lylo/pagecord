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
  variables = {}

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

    variable_notes = []
    markdown = translate_pika_variables(markdown, variable_notes)
    markdown = mark_pika_image_lines(normalize_markdown_hard_breaks(markdown))
    markdown = normalize_markdown_footnotes(markdown, id_prefix: slug.presence || File.basename(file, ".md"))
    content_doc = Nokogiri::HTML::DocumentFragment.parse(render_markdown_preserving_dynamic_variables(markdown))

    rewrite_pika_paths(content_doc)
    group_pika_galleries(content_doc)

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
      variables[label] = variable_notes if variable_notes.any?
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

  if variables.any?
    puts "\nPika variables were rewritten for Pagecord. These need checking:"
    variables.each do |label, notes|
      puts "  #{label}"
      notes.each { |note| puts "    #{note}" }
    end
  end

  if aliased.any?
    puts "\n#{aliased.size} posts were previously published at a different Pika slug."
    puts "Nothing serves those URLs on Pagecord, so links to them from elsewhere will 404:"
    aliased.first(10).each { |former, slug| puts "  /#{former} -> /#{slug}" }
    puts "  ...and #{aliased.size - 10} more" if aliased.size > 10
  end
  puts "====================="
end

# Pika and Pagecord both use {{ }} variables, but with different names and a
# different separator: Pika separates parameters with spaces, Pagecord with a
# pipe. Left alone a Pika variable either prints as literal text on the page or,
# worse, parses as a single parameter and silently filters nothing.
PIKA_VARIABLES = {
  "posts_in_stream" => [ "posts", { "style" => "stream" } ],
  "posts" => [ "posts", {} ],
  "posts_by_year" => [ "posts_by_year", {} ],
  "tags" => [ "tags", { "style" => "inline" } ],
  "newsletter_subscription_form" => [ "email_subscription", {} ]
}.freeze

# What Pagecord's post list accepts. Anything else - Pika's page_size, paginate,
# with_excerpts, skip - has no equivalent here: page size follows from the style,
# and a limit already turns pagination off.
PAGECORD_PARAMS = %w[style limit tag without_tag title emailed lang year sort heading].freeze

def translate_pika_variables(markdown, notes)
  markdown.gsub(/\{\{(.+?)\}\}/) do |original|
    name, params_string = $1.gsub("\\_", "_").strip.split(/\s+/, 2)
    pagecord_name, defaults = PIKA_VARIABLES[name]

    unless pagecord_name
      notes << "#{original.strip} - no Pagecord equivalent, left as it is"
      next original
    end

    params = defaults.merge(parse_pika_params(params_string))
    dropped = params.keys - PAGECORD_PARAMS
    notes << "#{original.strip} - dropped #{dropped.join(", ")}" if dropped.any?
    params = params.slice(*PAGECORD_PARAMS)

    [ "{{", pagecord_name, *params.map { |key, value| "| #{key}: #{value}" }, "}}" ].join(" ")
  end
end

def parse_pika_params(params_string)
  return {} if params_string.blank?

  params_string.scan(/(\w+):\s*("[^"]*"|\u201C[^\u201D]*\u201D|\S+)/).to_h do |key, value|
    [ key, value.gsub(/\A["\u201C]|["\u201D]\z/, "") ]
  end
end

PIKA_IMAGE = %r{!\[.*?\]\(\.\./images/[^)]*\)}

# Pika writes a gallery as several images on one line and a lone image on its own
# line. Markdown folds both into one paragraph, losing the grouping, so the line
# endings are made hard breaks and read back after rendering.
def mark_pika_image_lines(markdown)
  markdown.lines.map do |line|
    image_only_line?(line) ? "#{line.rstrip}  \n" : line
  end.join
end

def image_only_line?(line)
  line.include?("](../images/") && line.gsub(PIKA_IMAGE, "").strip.empty?
end

# Images that shared a line become a gallery, which is what Pika showed and what
# Lexxy builds when several images are added at once.
def group_pika_galleries(content_doc)
  content_doc.css("p").each do |paragraph|
    segments = [ [] ]
    paragraph.children.each do |node|
      node.element? && node.name == "br" ? segments << [] : segments.last << node
    end

    segments.each do |segment|
      images = segment.select { |node| node.element? && node.name == "img" }
      next if images.size < 2
      next unless segment.all? { |node| node.text? ? node.text.strip.empty? : node.name == "img" }

      gallery = Nokogiri::XML::Node.new("div", paragraph.document)
      gallery["class"] = "attachment-gallery attachment-gallery--#{images.size}"
      images.first.before(gallery)
      images.each { |image| gallery.add_child(image) }
    end

    drop_breaks_between_images(paragraph)
    lift_images_out_of_paragraph(paragraph)
  end
end

def drop_breaks_between_images(paragraph)
  paragraph.css("br").each do |break_node|
    neighbours = [ previous_meaningful(break_node), next_meaningful(break_node) ]
    break_node.remove if neighbours.all? { |node| node.nil? || image_like?(node) }
  end
end

# A gallery is a div, which cannot live inside a paragraph
def lift_images_out_of_paragraph(paragraph)
  children = paragraph.children.reject { |node| node.text? && node.text.strip.empty? }
  return unless children.any? && children.all? { |node| image_like?(node) }

  paragraph.replace(Nokogiri::HTML::DocumentFragment.parse(children.map(&:to_html).join))
end

def image_like?(node)
  node.element? && (node.name == "img" || node.classes.include?("attachment-gallery"))
end

def previous_meaningful(node)
  node = node.previous while node&.previous&.text? && node.previous.text.strip.empty?
  node.previous
end

def next_meaningful(node)
  node = node.next while node&.next&.text? && node.next.text.strip.empty?
  node.next
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
