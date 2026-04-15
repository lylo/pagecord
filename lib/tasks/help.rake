require "net/http"
require "json"
require "yaml"

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

    docs_dir = File.expand_path("../../docs/help-guide", __dir__)
    Dir.glob("#{docs_dir}/*.md").each do |file|
      slug = File.basename(file, ".md")
      raw = File.read(file)
      front_matter, _body = help_parse_front_matter(raw)
      status = front_matter["published"] ? "published" : "draft"
      content = help_rewrite_links(raw)

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

  def help_api_get(base_url, api_key, path)
    uri = URI("#{base_url}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
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

  def help_rewrite_links(raw)
    parts = raw.start_with?("---") ? raw.split("---", 3) : [ nil, nil, raw ]
    body = parts[2].gsub(/\]\(index\.md\)/, "](/)").gsub(/\]\(([^)]+)\.md\)/, '](/\1)')
    parts[1] ? "---#{parts[1]}---#{body}" : body
  end

  def help_parse_front_matter(content)
    return [ {}, content ] unless content.start_with?("---")
    parts = content.split("---", 3)
    front_matter = YAML.safe_load(parts[1], permitted_classes: [ Time, Date ]) || {}
    [ front_matter, parts[2].to_s.strip ]
  end
end
