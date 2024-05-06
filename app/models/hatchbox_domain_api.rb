class HatchboxDomainApi
  HATCHBOX_ENDPOINT = "https://app.hatchbox.io/api/v1/accounts/2928/apps/6347/domains"

  def initialize(user)
    @user = user
  end

  def add_domain(domain)
    return unless @user.custom_domain == domain

    response = HTTParty.post(HATCHBOX_ENDPOINT, headers: headers,
      body: {
        domain: {
          name: domain
        }
      }
    )
    Rails.logger.info "Response: #{response&.inspect}"

    if response.code == 200
      Rails.logger.info "SSL certificate issued for #{domain} for user #{@user.username}"
    else
      raise "Failed to add domain #{domain} for user #{@user.username}"
    end

    touch_all
  end

  def remove_domain(domain)
    return if restricted_domain(domain) || domain_exists?(domain)

    response = HTTParty.delete("#{HATCHBOX_ENDPOINT}/#{domain}", headers: headers)

    Rails.logger.info "Response: #{response&.inspect}"

    if response.code == 200
      Rails.logger.info "SSL certificate revoked for #{domain} for user #{@user.username}"
    else
      raise "Failed to remove domain #{domain} for user #{@user.username}"
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

    def touch_all
      @user.posts.touch_all
    end

    # In theory a malicious actor could remove domains that are not theirs, including
    # pagecord.com itself
    def restricted_domain(domain)
      %w[pagecord.com].include? domain
    end

    def domain_exists?(domain)
      User.where(custom_domain: domain).count > 0
    end
end