require "open-uri"
require "nokogiri"
require "yaml"
require_relative "import_helpers"

# Usage: ruby import_markdown.rb path/to/markdown/directory_or_file blog_subdomain [--assets-root=/path/to/assets] [--dry-run]
def import_markdown(path, blog_subdomain, assets_root: nil, dry_run: false)
  include ImportHelpers
  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  if assets_root
    puts "Using assets root: #{assets_root}"
    unless File.directory?(assets_root)
      puts "Warning: Assets root directory not found: #{assets_root}"
    end
  end

  # Find all markdown files - handle both single files and directories
  markdown_files = []

  if File.file?(path)
    if path.end_with?(".md")
      markdown_files = [ path ]
    else
      puts "File #{path} is not a markdown file (must end with .md)"
      return
    end
  elsif File.directory?(path)
    markdown_files = Dir.glob(File.join(path, "*.md"))
    if markdown_files.empty?
      puts "No markdown files found in #{path}"
      return
    end
  else
    puts "Path not found: #{path}"
    return
  end

  puts "Found #{markdown_files.length} markdown files to import"

  success_count = 0
  failed_count = 0
  skipped_count = 0

  markdown_files.each do |file_path|
    puts "Processing file: #{File.basename(file_path)}"

    content = File.read(file_path)
    front_matter, markdown_content = extract_front_matter(content)
    slug = front_matter["slug"]&.to_s
    published_at_value = front_matter["published_at"] || front_matter["published_date"] || front_matter["date"]
    published_at = parse_datetime(
      published_at_value&.to_s,
      fallback_message: "Warning: Could not parse date for #{File.basename(file_path)}"
    )
    tag_list = parse_markdown_tags(front_matter["tags"])
    is_page = truthy?(front_matter["is_page"]) || front_matter["type"].to_s == "page"
    status = falsey?(front_matter["publish"]) || front_matter["status"].to_s == "draft" ? :draft : :published
    markdown_content = markdown_content.gsub(/<!--\s*more\s*-->/, "")
    markdown_content = normalize_markdown_dynamic_variables(markdown_content, is_page: is_page, published_at: published_at)
    markdown_content = normalize_markdown_hard_breaks(markdown_content)
    markdown_content = normalize_markdown_footnotes(markdown_content, id_prefix: slug.presence || File.basename(file_path, ".md"))
    html_content = render_markdown_preserving_dynamic_variables(markdown_content)
    parsed_html = Nokogiri::HTML::DocumentFragment.parse(html_content)

    # Extract title from front matter first, then fall back to first H1
    title = front_matter["title"]&.to_s

    # If no title in front matter, try to extract from first H1 in content
    if title.nil?
      first_element = parsed_html.children.find { |child| !child.text.strip.empty? }
      if first_element && first_element.name == "h1"
        title = first_element.text.strip
        first_element.remove
        html_content = parsed_html.to_html
      end
    end

    # Check if post already exists by title (case-insensitive) or slug
    existing_post = post_exists?(blog, title) || post_exists_by_slug(blog, slug)

    if existing_post
      puts "Skipping duplicate post: #{title || File.basename(file_path)} (matches existing: '#{existing_post.title}', slug: '#{existing_post.slug}')"
      skipped_count += 1
      next
    end

    # Create the Post object (without content yet, so we don't trigger ActionText parsing of <img>)
    post = blog.all_posts.new(
      title: title,
      slug: slug,
      published_at: published_at,
      tag_list: tag_list,
      is_page: is_page,
      status: status
    )

    # Process images and create ActionText content
    begin
      post.content = process_images_to_actiontext(html_content, assets_root: assets_root, dry_run: dry_run)
    rescue => e
      puts "Skipping post due to image processing failure: #{title || File.basename(file_path)} - #{e.message}"
      failed_count += 1
      next
    end

    if dry_run
      puts "[DRY RUN] Would create #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
      puts "[DRY RUN] Published at: #{published_at}"
      puts "[DRY RUN] Slug: #{post.slug}" if post.slug.present?
      puts "[DRY RUN] Tags: #{tag_list.join(", ")}" if tag_list.any?
      puts "[DRY RUN] Content length: #{post.content.to_plain_text.length} characters"

      # Validate without saving
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
      puts "Successfully created #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
      success_count += 1
    else
      puts "Failed to create #{is_page ? 'page' : 'post'}: #{title || File.basename(file_path)}"
      puts post.errors.full_messages
      failed_count += 1
      next
    end
  end

  puts "\n=== IMPORT SUMMARY ==="
  puts "Total files processed: #{markdown_files.length}"
  puts "Successful: #{success_count}"
  puts "Failed: #{failed_count}"
  puts "Skipped (duplicates): #{skipped_count}"
  puts "====================="
end

def extract_front_matter(content)
  stripped = content.strip
  return [ {}, content ] unless stripped.start_with?("---")

  parts = stripped.split("---", 3)
  return [ {}, content ] unless parts.length >= 3

  front_matter = YAML.safe_load(parts[1], permitted_classes: [ Date, Time ]) || {}
  [ front_matter.transform_keys(&:to_s), parts[2].strip ]
rescue Psych::SyntaxError => e
  raise Post::FrontMatter::InvalidError, e.message
end

def parse_markdown_tags(tags)
  Array(tags)
    .flat_map { |tag| tag.to_s.split(",") }
    .map { |tag| clean_tag(tag) }
    .reject(&:empty?)
end

def normalize_markdown_hard_breaks(markdown)
  markdown.gsub(/\\\r?\n/, "  \n")
end

def normalize_markdown_dynamic_variables(markdown, is_page:, published_at:)
  normalized = markdown.gsub(/\{\{\s*post_published_date\s*\}\}/, published_at.strftime("%-d %B %Y"))
  return normalized.gsub(/\{\{\s*post_last_modified\s*\}\}/, "{{ updated_at }}") if is_page

  normalized.lines.reject { |line| line.match?(/\{\{.*?\}\}/) }.join
end

def normalize_markdown_footnotes(markdown, id_prefix:)
  definitions = []
  body_lines = []
  current_definition = nil

  markdown.each_line do |line|
    stripped_line = line.chomp.delete_suffix("\r")

    if (match = stripped_line.match(/\A\[\^([^\]]+)\]:\s*(.*)\z/))
      current_definition = { label: match[1], lines: [ match[2] ] }
      definitions << current_definition
    elsif current_definition && stripped_line.match?(/\A(?: {2,}|\t)\S/)
      current_definition[:lines] << stripped_line.sub(/\A(?: {2,}|\t)/, "").rstrip
    else
      current_definition = nil unless line.strip.empty?
      body_lines << line
    end
  end

  return markdown if definitions.empty?

  id_base = id_prefix.to_s.parameterize.presence || "footnote"
  note_numbers = definitions.each_with_index.to_h { |definition, index| [ definition[:label], index + 1 ] }
  body = body_lines.join.gsub(/\[\^([^\]]+)\]/) do |reference|
    number = note_numbers[$1]
    number ? %Q(<a id="#{id_base}-fnref-#{number}" href="##{id_base}-fn-#{number}">[#{number}]</a>) : reference
  end

  notes = definitions.each_with_index.map do |definition, index|
    number = index + 1
    content = definition[:lines].join("\n").strip
    "#{number}. <span id=\"#{id_base}-fn-#{number}\"></span>#{content}"
  end

  "#{body.strip}\n\n---\n\n**Notes**\n\n#{notes.join("\n")}"
end

def render_markdown_preserving_dynamic_variables(markdown)
  variables = []
  protected_markdown = markdown.gsub(/\{\{.*?\}\}/) do |variable|
    variables << variable
    "PAGECORDDYNAMICVARIABLE#{variables.length - 1}TOKEN"
  end

  _attributes, html = Post::Markdown.render(protected_markdown)
  variables.each_with_index do |variable, index|
    html = html.gsub("PAGECORDDYNAMICVARIABLE#{index}TOKEN", variable)
  end
  html
end

def post_exists_by_slug(blog, slug)
  return false if slug.blank?

  blog.all_posts.find_by(slug: slug)
end

def truthy?(value)
  ActiveModel::Type::Boolean.new.cast(value)
end

def falsey?(value)
  !value.nil? && !truthy?(value)
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2
    puts "Usage: bundle exec rails runner import_markdown.rb path/to/markdown/directory_or_file blog_subdomain [--assets-root=/path/to/assets] [--dry-run]"
    puts "Examples:"
    puts "  bundle exec rails runner import_markdown.rb ./markdown_posts myblog"
    puts "  bundle exec rails runner import_markdown.rb ./single_post.md myblog --dry-run"
    puts "  bundle exec rails runner import_markdown.rb ~/dev/mysite/_posts myblog --assets-root=~/dev/mysite"
    return
  end

  path = ARGV[0]
  blog_subdomain = ARGV[1]

  # Parse optional flags
  dry_run = false
  assets_root = nil

  ARGV[2..-1]&.each do |arg|
    if arg == "--dry-run"
      dry_run = true
    elsif arg.start_with?("--assets-root=")
      assets_root = arg.split("=", 2)[1]
      # Expand ~ to home directory
      assets_root = File.expand_path(assets_root) if assets_root
    end
  end

  if dry_run
    puts "=== DRY RUN MODE - No posts will be created ==="
  end

  import_markdown(path, blog_subdomain, assets_root: assets_root, dry_run: dry_run)
end
