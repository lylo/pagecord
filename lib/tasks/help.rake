namespace :help do
  desc "Sync help guide markdown files to help.pagecord.com pages"
  task sync: :environment do
    subdomain = ENV.fetch("BLOG", "help")
    blog = Blog.find_by(subdomain: subdomain)
    abort "Blog '#{subdomain}' not found" unless blog

    dry_run = ENV["DRY_RUN"].present?
    puts "DRY RUN - no changes will be saved\n\n" if dry_run

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true, with_toc_data: true),
      autolink: true, tables: true, fenced_code_blocks: true
    )

    Dir.glob(Rails.root.join("docs/help-guide/*.md")).each do |file|
      slug = File.basename(file, ".md")
      raw = File.read(file)
      front_matter, body = parse_front_matter(raw)
      title = front_matter["title"] || body[/^#\s+(.+)$/, 1]
      body = body.gsub(/\]\(([^)]+)\.md\)/, '](/\1)')  # Convert .md links to absolute paths
      html = markdown.render(body)

      page = if slug == "index"
        blog.home_page || Post.new(blog: blog, is_page: true)
      else
        Post.find_or_initialize_by(blog: blog, slug: slug, is_page: true)
      end
      existing_content_html = normalize_html(page.content.body&.to_html)
      new_content_html = normalize_html(ActionText::Content.new(html).to_html)
      page.assign_attributes(
        title: title,
        content: html,
        status: front_matter["published"] ? "published" : "draft"
      )
      content_changed = new_content_html != existing_content_html

      if page.new_record?
        puts "CREATE: #{slug}"
        unless dry_run
          page.save!
          blog.update!(home_page: page) if slug == "index"
        end
      elsif page.changed? || content_changed
        reasons = []
        reasons << "attributes: #{page.changes.keys.join(', ')}" if page.changed?
        reasons << "content" if content_changed
        puts "UPDATE: #{slug} (#{reasons.join(', ')})"
        if ENV["DEBUG"] && content_changed
          puts "  new (first 200): #{new_content_html[0..200].inspect}"
          puts "  old (first 200): #{existing_content_html[0..200].inspect}"
        end
        page.save! unless dry_run
      else
        puts "unchanged: #{slug}"
      end
    end
  end

  def normalize_html(html)
    return "" if html.nil?
    html
      .gsub(/>\s+</, "><")           # strip whitespace between tags
      .gsub(/<b>(<strong>.*?<\/strong>)<\/b>/, '\1')  # unwrap <b> around <strong>
      .gsub(/ id="[^"]*"/, "")       # strip heading id attributes
      .strip
  end

  def parse_front_matter(content)
    return [ {}, content ] unless content.start_with?("---")

    parts = content.split("---", 3)
    front_matter = YAML.safe_load(parts[1], permitted_classes: [ Time, Date ]) || {}
    [ front_matter, parts[2].to_s.strip ]
  end
end
