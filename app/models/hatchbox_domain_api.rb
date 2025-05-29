class HatchboxDomainApi
  def initialize(blog)
    @blog = blog
  end

  def add_domain(domain)
    return unless @blog.custom_domain == domain

    response = HTTParty.post(hatchbox_api_endpoint, headers: headers,
      body: {
        domain: {
          name: domain
        }
      }
    )
    Rails.logger.info "Response: #{response&.inspect}"

    if response.code == 200
      Rails.logger.info "SSL certificate issued for #{domain} for blog #{@blog.subdomain}"
    else
      raise "Failed to add domain #{domain} for blog #{@blog.subdomain}"
    end

    touch_all
  end

  def remove_domain(domain)
    return if restricted_domain(domain) || domain_exists?(domain)

    response = HTTParty.delete("#{hatchbox_api_endpoint}/#{domain}", headers: headers)

    Rails.logger.info "Response: #{response&.inspect}"

    if response.code == 200
      Rails.logger.info "SSL certificate revoked for #{domain} for blog #{@blog.subdomain}"
    else
      raise "Failed to remove domain #{domain} for blog #{@blog.subdomain}"
    end

    touch_all
  end

  private

    def headers
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{ENV['HATCHBOX_API_KEY']}"
      }
    end

    def hatchbox_api_endpoint
      ENV["HATCHBOX_API_ENDPOINT"]
    end

    def touch_all
      @blog.posts.touch_all
    end

    # In theory a malicious actor could remove domains that are not theirs, including
    # pagecord.com itself
    def restricted_domain(domain)
      %w[pagecord.com proxy.pagecord.com].include? domain
    end

    def domain_exists?(domain)
      Blog.where(custom_domain: domain).count > 0
    end
end
