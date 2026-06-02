require "net/http"
require "json"
require "yaml"
require "erb"

namespace :help do
  desc "Sync help guide markdown files to help.pagecord.com pages via API"
  task :sync do
    api_key = ENV.fetch("PAGECORD_API_KEY") { abort "PAGECORD_API_KEY is required" }
    base_url = ENV.fetch("PAGECORD_API_URL", "https://api.pagecord.com")
    dry_run = ENV["DRY_RUN"].present?
    puts "Target: #{base_url}"
    puts "DRY RUN - no changes will be saved\n\n" if dry_run

    # Build slug → token map from all existing pages (published and draft)
    existing = {}
    [ "published", "draft" ].each do |status|
      page_num = 1
      loop do
        res = help_api_get(base_url, api_key, "/pages?status=#{status}&page=#{page_num}")
        abort "API error #{res.code}: #{res.body}" unless res.code.start_with?("2")
        JSON.parse(res.body).each { |p| existing[p["slug"]] = p["token"] }
        break unless res["Link"]&.include?('rel="next"')
        page_num += 1
      end
    end
    home_res = help_api_get(base_url, api_key, "/home_page")
    home_token = home_res.code == "200" ? JSON.parse(home_res.body)["token"] : nil

    docs_dir = help_docs_dir
    Dir.glob("#{docs_dir}/*.md").each do |file|
      slug = File.basename(file, ".md")
      next if ENV["SLUG"] && ENV["SLUG"] != slug
      raw = File.read(file)
      front_matter, _body = help_parse_front_matter(raw)
      status = front_matter["published"] ? "published" : "draft"
      content = help_prepare_content(raw, front_matter, slug)

      if slug == "index"
        if home_token
          puts "UPDATE: home_page"
          help_api_call(:patch, base_url, api_key, "/pages/#{home_token}",
            content: content, content_format: "markdown", status: status) unless dry_run
        else
          puts "CREATE: home_page"
          help_api_call(:post, base_url, api_key, "/home_page",
            content: content, content_format: "markdown", status: status) unless dry_run
        end
      elsif (token = existing[slug])
        puts "UPDATE: #{slug}"
        help_api_call(:patch, base_url, api_key, "/pages/#{token}",
          content: content, content_format: "markdown", status: status) unless dry_run
      else
        puts "CREATE: #{slug}"
        help_api_call(:post, base_url, api_key, "/pages",
          content: content, content_format: "markdown", status: status, slug: slug) unless dry_run
      end
    end
  end

  desc "Upload missing help guide attachments and write returned SGIDs to front matter"
  task :upload_attachments do
    api_key = ENV.fetch("PAGECORD_API_KEY") { abort "PAGECORD_API_KEY is required" }
    base_url = ENV.fetch("PAGECORD_API_URL", "https://api.pagecord.com")
    dry_run = ENV["DRY_RUN"].present?
    force = ENV["FORCE"].present?
    puts "Target: #{base_url}"
    puts "DRY RUN - no changes will be saved\n\n" if dry_run

    docs_dir = help_docs_dir
    sgids_by_path = {}
    pending_writes = []

    Dir.glob("#{docs_dir}/*.md").each do |file|
      slug = File.basename(file, ".md")
      next if ENV["SLUG"] && ENV["SLUG"] != slug

      raw = File.read(file)
      front_matter, body = help_parse_front_matter(raw)
      attachments = front_matter["attachments"]
      next unless attachments.is_a?(Hash)

      changed = false
      attachments.each do |key, attachment|
        next unless attachment.is_a?(Hash)
        next if attachment["sgid"].present? && !force

        relative_path = attachment["file"].to_s
        abort "Missing attachment file path for #{slug}: #{key}" if relative_path.blank?

        path = File.expand_path(relative_path, docs_dir)
        abort "Attachment file not found for #{slug}: #{key} (#{relative_path})" unless File.exist?(path)

        if sgids_by_path[path]
          puts "REUSE: #{slug}: #{key} -> #{relative_path}"
          attachment["sgid"] = sgids_by_path[path]
        else
          puts "#{force && attachment["sgid"].present? ? "REUPLOAD" : "UPLOAD"}: #{slug}: #{key} -> #{relative_path}"
          if dry_run
            sgids_by_path[path] = "dry-run"
            next
          end

          sgids_by_path[path] = help_upload_attachment(base_url, api_key, path)
          attachment["sgid"] = sgids_by_path[path]
        end
        changed = true
      end

      pending_writes << [ file, raw, attachments ] if changed && !dry_run
    end

    pending_writes.each do |file, raw, attachments|
      File.write(file, help_update_attachment_sgids(raw, attachments))
    end
  end

  def help_api_get(base_url, api_key, path)
    uri = URI("#{base_url}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
  end

  def help_docs_dir
    ENV["DOCS_DIR"].presence || File.expand_path("../../docs/help-guide", __dir__)
  end

  def help_api_call(method, base_url, api_key, path, params)
    uri = URI("#{base_url}#{path}")
    req = (method == :post ? Net::HTTP::Post : Net::HTTP::Patch).new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    req.set_form_data(params)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
    abort "API error #{res.code}: #{res.body}" unless res.code.start_with?("2")
    res
  end

  def help_upload_attachment(base_url, api_key, path)
    uri = URI("#{base_url}/attachments")
    file = File.open(path, "rb")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    req.set_form(
      [ [ "file", file, { filename: File.basename(path), content_type: help_content_type(path) } ] ],
      "multipart/form-data"
    )
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
    abort "API error #{res.code}: #{res.body}" unless res.code.start_with?("2")

    JSON.parse(res.body).fetch("attachable_sgid")
  ensure
    file&.close
  end

  def help_content_type(path)
    case File.extname(path).downcase
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".gif" then "image/gif"
    when ".webp" then "image/webp"
    when ".mp4" then "video/mp4"
    when ".mov" then "video/quicktime"
    when ".mp3" then "audio/mpeg"
    when ".wav" then "audio/wav"
    else "application/octet-stream"
    end
  end

  def help_rewrite_links(raw)
    parts = raw.start_with?("---") ? raw.split("---", 3) : [ nil, nil, raw ]
    body = parts[2].gsub(/\]\(index\.md\)/, "](/)").gsub(/\]\(([^)]+)\.md\)/, '](/\1)')
    parts[1] ? "---#{parts[1]}---#{body}" : body
  end

  def help_prepare_content(raw, front_matter, slug)
    content = help_rewrite_links(raw)
    help_render_attachments(content, front_matter.fetch("attachments", {}), slug)
  end

  def help_render_attachments(content, attachments, slug)
    content.gsub(/\{\{\s*attachment:\s*([\w-]+)\s*\}\}/) do
      key = Regexp.last_match(1)
      attachment = attachments[key]
      sgid = attachment.is_a?(Hash) ? attachment["sgid"] : attachment
      if sgid.to_s.strip.empty?
        abort "Missing attachment sgid for #{slug}: #{key}"
      end
      next "" if ENV["SKIP_HELP_ATTACHMENTS"].present?

      %(<action-text-attachment sgid="#{ERB::Util.html_escape(sgid)}"></action-text-attachment>)
    end
  end

  def help_parse_front_matter(content)
    return [ {}, content ] unless content.start_with?("---")
    parts = content.split("---", 3)
    front_matter = YAML.safe_load(parts[1], permitted_classes: [ Time, Date ]) || {}
    [ front_matter, parts[2].to_s.strip ]
  end

  def help_update_attachment_sgids(raw, attachments)
    parts = raw.split("---", 3)
    front_matter = parts[1]
    body = parts[2]

    attachments.each do |key, attachment|
      next unless attachment.is_a?(Hash) && attachment["sgid"].present?

      escaped_key = Regexp.escape(key)
      escaped_sgid = attachment["sgid"].to_s.gsub("\\", "\\\\\\").gsub("\"", "\\\\\"")
      pattern = /^(\s{2}#{escaped_key}:\n(?:(?!\s{2}[\w-]+:).*\n)*?\s{4}sgid:).*$/
      front_matter = front_matter.sub(pattern, "\\1 \"#{escaped_sgid}\"")
    end

    "---#{front_matter}---#{body}"
  end
end
