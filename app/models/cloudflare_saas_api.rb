class CloudflareSaasApi
  def initialize(blog)
    @blog = blog
  end

  def add_domain(domain)
    return unless @blog.custom_domain == domain

    response = HTTParty.post(
      "#{base_url}/custom_hostnames",
      headers: headers,
      body: {
        hostname: domain,
        ssl: { method: "http", type: "dv" }
      }.to_json
    )

    unless response.success?
      raise "Failed to add custom hostname #{domain} for blog #{@blog.subdomain}: #{response.code} #{response.body}"
    end

    hostname_id = response.parsed_response.dig("result", "id")
    @blog.update_column(:cloudflare_custom_hostname_id, hostname_id)
  end

  def remove_domain(domain)
    return if restricted_domain?(domain) || domain_in_use?(domain)

    hostname_id = @blog.cloudflare_custom_hostname_id
    return unless hostname_id.present?

    response = HTTParty.delete(
      "#{base_url}/custom_hostnames/#{hostname_id}",
      headers: headers
    )

    unless response.success?
      raise "Failed to remove custom hostname #{domain} for blog #{@blog.subdomain}: #{response.code} #{response.body}"
    end

    @blog.update_column(:cloudflare_custom_hostname_id, nil)
  end

  def status
    hostname_id = @blog.cloudflare_custom_hostname_id
    return unless hostname_id.present?

    response = HTTParty.get(
      "#{base_url}/custom_hostnames/#{hostname_id}",
      headers: headers
    )

    return unless response.success?

    response.parsed_response["result"]
  end

  private

    def headers
      {
        "Authorization" => "Bearer #{ENV['CLOUDFLARE_API_TOKEN']}",
        "Content-Type" => "application/json"
      }
    end

    def base_url
      "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}"
    end

    def restricted_domain?(domain)
      %w[pagecord.com proxy.pagecord.com domains.pagecord.com].include?(domain)
    end

    def domain_in_use?(domain)
      Blog.where(custom_domain: domain).count > 0
    end
end
