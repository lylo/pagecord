module Blog::Hosts
  extend ActiveSupport::Concern

  def host
    custom_domain.presence || "#{subdomain}.#{Rails.application.config.x.domain}"
  end

  def external_url?(url)
    url = url.to_s
    uri = URI.parse(url.start_with?("//") ? "https:#{url}" : url)
    return false unless uri.is_a?(URI::HTTP) && uri.host.present?

    !hosts.include?(uri.host.downcase)
  rescue URI::Error
    false
  end

  # A blog stays reachable on its subdomain after a custom domain is set, so a
  # post URL is matched against both.
  def find_post_by_url(url)
    uri = URI.parse(url.to_s)
    return unless hosts.include?(uri.host&.downcase)

    posts.kept.find_by(slug: uri.path.delete_prefix("/").chomp("/").delete_prefix("posts/"))
  rescue URI::Error
    nil
  end

  private

    def hosts
      hosts = [ "#{subdomain}.#{Rails.application.config.x.domain}" ]

      if custom_domain.present?
        apex = custom_domain.delete_prefix("www.")
        hosts += [ apex, "www.#{apex}" ]
      end

      hosts.map(&:downcase)
    end
end
