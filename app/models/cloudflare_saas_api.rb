class CloudflareSaasApi
  REQUEST_TIMEOUT = 5
  STATUS_TIMEOUT = 2

  def initialize(blog)
    @blog = blog
  end

  def add_domain(domain)
    return unless @blog.reload.custom_domain == domain

    if existing_hostname = find_hostname(domain)
      save_hostname(domain, existing_hostname["id"])
      return existing_hostname
    end

    response = HTTParty.post(
      "#{base_url}/custom_hostnames",
      headers: headers,
      timeout: REQUEST_TIMEOUT,
      body: {
        hostname: domain,
        ssl: { method: "http", type: "dv" }
      }.to_json
    )

    unless response.success?
      if hostname_exists?(response) && (existing_hostname = find_hostname(domain))
        save_hostname(domain, existing_hostname["id"])
        return existing_hostname
      end

      raise "Failed to add custom hostname #{domain} for blog #{@blog.subdomain}: #{response.code} #{response.body}"
    end

    hostname_id = response.parsed_response.dig("result", "id")
    save_hostname(domain, hostname_id)

    response.parsed_response["result"]
  end

  def remove_domain(domain)
    return if restricted_domain?(domain) || domain_in_use?(domain)

    hostname = stored_hostname(domain)
    hostname_id = hostname&.external_id || find_hostname(domain)&.dig("id")
    return unless hostname_id.present?

    response = HTTParty.delete(
      "#{base_url}/custom_hostnames/#{hostname_id}",
      headers: headers,
      timeout: REQUEST_TIMEOUT
    )

    unless response.success? || response.code == 404
      raise "Failed to remove custom hostname #{domain} for blog #{@blog.subdomain}: #{response.code} #{response.body}"
    end

    hostname&.destroy!
  end

  def status
    hostname = current_hostname
    return unless hostname

    response = HTTParty.get(
      "#{base_url}/custom_hostnames/#{hostname.external_id}",
      headers: headers,
      timeout: STATUS_TIMEOUT
    )

    return unless response.success?

    response.parsed_response["result"]
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
    nil
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

    def find_hostname(domain)
      response = HTTParty.get(
        "#{base_url}/custom_hostnames",
        headers: headers,
        query: { hostname: domain },
        timeout: REQUEST_TIMEOUT
      )

      return unless response.success?

      Array(response.parsed_response["result"]).find { |hostname| hostname["hostname"] == domain }
    end

    def hostname_exists?(response)
      response.code == 409 ||
        Array(response.parsed_response["errors"]).any? { |error| error["message"].to_s.match?(/already exists/i) }
    end

    def current_hostname
      return unless @blog.custom_domain.present?

      stored_hostname(@blog.custom_domain)
    end

    def stored_hostname(domain)
      CloudflareCustomHostname.find_by(blog: @blog, domain:)
    end

    def save_hostname(domain, hostname_id)
      return unless hostname_id.present?

      return unless Blog.exists?(id: @blog.id, custom_domain: domain)

      CloudflareCustomHostname
        .find_or_initialize_by(blog: @blog, domain:)
        .update!(external_id: hostname_id)
    end

    def restricted_domain?(domain)
      %w[pagecord.com proxy.pagecord.com domains.pagecord.com].include?(domain)
    end

    def domain_in_use?(domain)
      Blog.exists?(custom_domain: domain)
    end
end
