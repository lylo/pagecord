# Manages Cloudflare for SaaS custom hostnames for blog custom domains.
# Pagecord treats apex and www variants as the same customer domain for redirects,
# so both hostnames are provisioned and removed together. Removing a domain can
# also run after the blog has been deleted, as long as the old domain is supplied.
class CloudflareSaasApi
  REQUEST_TIMEOUT = 5

  def initialize(blog = nil)
    @blog = blog
  end

  def add_domain(domain)
    return unless @blog&.reload&.custom_domain == domain

    hostnames_for(domain).filter_map { |hostname| add_hostname(hostname) }
  end

  def remove_domain(domain)
    hostnames_for(domain).each { |hostname| remove_hostname(hostname) }
  end

  private

    def add_hostname(hostname)
      if existing_hostname = find_hostname(hostname)
        save_hostname(hostname, existing_hostname)
        return existing_hostname
      end

      response = HTTParty.post(
        "#{base_url}/custom_hostnames",
        headers: headers,
        timeout: REQUEST_TIMEOUT,
        body: {
          hostname: hostname,
          ssl: { method: "http", type: "dv" }
        }.to_json
      )

      unless response.success?
        if hostname_exists?(response) && (existing_hostname = find_hostname(hostname))
          save_hostname(hostname, existing_hostname)
          return existing_hostname
        end

        raise "Failed to add custom hostname #{hostname} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      result = response.parsed_response["result"]
      save_hostname(hostname, result)

      result
    end

    def remove_hostname(hostname)
      return if hostname_in_use?(hostname)

      hostname_record = stored_hostname(hostname)
      hostname_id = hostname_record&.external_id || find_hostname(hostname)&.dig("id")
      return unless hostname_id.present?

      response = HTTParty.delete(
        "#{base_url}/custom_hostnames/#{hostname_id}",
        headers: headers,
        timeout: REQUEST_TIMEOUT
      )

      unless response.success? || response.code == 404
        raise "Failed to remove custom hostname #{hostname} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      hostname_record&.destroy!
    end

    def headers
      {
        "Authorization" => "Bearer #{ENV["CLOUDFLARE_API_TOKEN"]}",
        "Content-Type" => "application/json"
      }
    end

    def base_url
      "https://api.cloudflare.com/client/v4/zones/#{ENV["CLOUDFLARE_ZONE_ID"]}"
    end

    def find_hostname(hostname)
      response = HTTParty.get(
        "#{base_url}/custom_hostnames",
        headers: headers,
        query: { hostname: hostname },
        timeout: REQUEST_TIMEOUT
      )

      return unless response.success?

      Array(response.parsed_response["result"]).find { |result| result["hostname"] == hostname }
    end

    def hostname_exists?(response)
      response.code == 409 ||
        Array(response.parsed_response["errors"]).any? { |error| error["message"].to_s.match?(/already exists/i) }
    end

    def stored_hostname(hostname)
      CloudflareCustomHostname.find_by(domain: hostname)
    end

    def save_hostname(hostname, result)
      hostname_id = result.is_a?(Hash) ? result["id"] : result
      return unless hostname_id.present?
      return unless hostnames_for(@blog&.reload&.custom_domain).include?(hostname)

      CloudflareCustomHostname
        .find_or_initialize_by(domain: hostname)
        .update!(
          blog: @blog,
          external_id: hostname_id
        )
    end

    def hostname_in_use?(hostname)
      Blog.where(custom_domain: hostnames_for(hostname)).exists?
    end

    def hostnames_for(domain)
      Blog.custom_domain_hostnames(domain)
    end

    def blog_label
      @blog&.subdomain || "deleted blog"
    end
end
