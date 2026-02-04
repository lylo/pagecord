namespace :help do
  desc "Sync help guide markdown files to help.pagecord.com pages"
  task sync: :environment do
    subdomain = ENV.fetch("BLOG", "help")
    blog = Blog.find_by(subdomain: subdomain)
    abort "Blog '#{subdomain}' not found" unless blog

    dry_run = ENV["DRY_RUN"].present?
    puts "DRY RUN - no changes will be saved\n\n" if dry_run

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true),
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
      page.assign_attributes(
        title: title,
        content: html,
        status: front_matter["published"] ? "published" : "draft"
      )

      if page.new_record?
        puts "CREATE: #{slug}"
        unless dry_run
          page.save!
          blog.update!(home_page: page) if slug == "index"
        end
      elsif page.changed?
        puts "UPDATE: #{slug}"
        page.save! unless dry_run
      else
        puts "unchanged: #{slug}"
      end
    end
  end

  def parse_front_matter(content)
    return [{}, content] unless content.start_with?("---")

    parts = content.split("---", 3)
    front_matter = YAML.safe_load(parts[1], permitted_classes: [Time, Date]) || {}
    [front_matter, parts[2].to_s.strip]
  end
end
