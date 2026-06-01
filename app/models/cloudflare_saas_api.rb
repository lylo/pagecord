# Manages Cloudflare for SaaS custom hostnames for blog custom domains.
# Pagecord treats apex and www variants as the same customer domain for redirects,
# so both hostnames are provisioned and removed together. Removing a domain can
# also run after the blog has been deleted, as long as the old domain is supplied.
class CloudflareSaasApi
  MIN_TLS_VERSION = "1.2"

  def initialize(blog = nil)
    @blog = blog
  end

  # Creates Cloudflare custom hostnames for the blog's current custom domain.
  # Includes the apex/www pair so Rails can keep redirecting either variant to
  # the canonical custom domain.
  def add_domain(domain)
    return unless @blog&.reload&.custom_domain == domain

    hostnames_for(domain).filter_map { |hostname| add_hostname(hostname) }
  end

  # Removes Cloudflare custom hostnames for a previously configured domain.
  # Removal can run after the blog has gone, but active domains owned by any blog
  # are left alone.
  def remove_domain(domain)
    hostnames_for(domain).each { |hostname| remove_hostname(hostname) }
  end

  # Cloudflare backs off hostname validation when customers save a domain before
  # pointing DNS at the SaaS target. A no-op PATCH nudges validation to run again.
  def refresh_domain_validation(domain)
    return [] unless @blog&.reload&.custom_domain == domain

    hostnames_for(domain).filter_map { |hostname| refresh_hostname_validation(hostname) }
  end

  def update_domain(domain)
    return [] unless @blog&.reload&.custom_domain == domain

    hostnames_for(domain).filter_map { |hostname| update_hostname(hostname) }
  end

  private

    # Ensures a single hostname exists in Cloudflare and stores the Cloudflare
    # hostname ID locally for later deletion or ownership transfer.
    def add_hostname(hostname)
      if existing_hostname = find_hostname(hostname)
        # A previous attempt may have reached Cloudflare but failed before
        # storing the hostname ID locally, so reconcile the local record.
        save_hostname(hostname, existing_hostname)
        return existing_hostname
      end

      response = HTTParty.post(
        "#{base_url}/custom_hostnames",
        headers: headers,
        body: {
          hostname: hostname,
          ssl: ssl_options
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
        headers: headers
      )

      unless response.success? || response.code == 404
        raise "Failed to remove custom hostname #{hostname} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      hostname_record&.destroy!
    end

    def refresh_hostname_validation(hostname)
      hostname_record = stored_hostname(hostname)
      return unless hostname_record

      result = fetch_hostname(hostname_record.external_id)
      return if active_hostname?(result)

      response = HTTParty.patch(
        "#{base_url}/custom_hostnames/#{hostname_record.external_id}",
        headers: headers,
        body: {
          ssl: ssl_options
        }.to_json
      )

      unless response.success?
        raise "Failed to refresh custom hostname #{hostname} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      response.parsed_response["result"]
    end

    def update_hostname(hostname)
      hostname_record = stored_hostname(hostname)
      return unless hostname_record

      response = HTTParty.patch(
        "#{base_url}/custom_hostnames/#{hostname_record.external_id}",
        headers: headers,
        body: {
          ssl: ssl_options
        }.to_json
      )

      unless response.success?
        raise "Failed to update custom hostname #{hostname} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      response.parsed_response["result"]
    end

    def headers
      {
        "Authorization" => "Bearer #{ENV["CLOUDFLARE_API_TOKEN"]}",
        "Content-Type" => "application/json"
      }
    end

    def ssl_options
      {
        method: "http",
        type: "dv",
        settings: { min_tls_version: MIN_TLS_VERSION }
      }
    end

    def base_url
      "https://api.cloudflare.com/client/v4/zones/#{ENV["CLOUDFLARE_ZONE_ID"]}"
    end

    def find_hostname(hostname)
      response = HTTParty.get(
        "#{base_url}/custom_hostnames",
        headers: headers,
        query: { hostname: hostname }
      )

      return unless response.success?

      Array(response.parsed_response["result"]).find { |result| result["hostname"] == hostname }
    end

    def fetch_hostname(hostname_id)
      response = HTTParty.get(
        "#{base_url}/custom_hostnames/#{hostname_id}",
        headers: headers
      )

      unless response.success?
        raise "Failed to fetch custom hostname #{hostname_id} for blog #{blog_label}: #{response.code} #{response.body}"
      end

      response.parsed_response["result"]
    end

    def active_hostname?(result)
      result["status"] == "active" && result.dig("ssl", "status") == "active"
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
