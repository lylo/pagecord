module Blog::RelMe
  extend ActiveSupport::Concern

  MAX_REL_ME_LINKS = 10

  # Platforms whose profiles participate in rel=me verification, either by
  # emitting rel=me on profile links or by verifying links back to this blog
  REL_ME_PLATFORMS = %w[ Email GitHub Mastodon Pixelfed Threads ].freeze

  included do
    validate :rel_me_links_valid
  end

  # Explicit identity links (one per line) when set, otherwise inferred from
  # social navigation items. Emitted as <link rel="me"> in the blog head.
  def rel_me_urls
    urls = explicit_rel_me_links.presence ||
      social_navigation_items.ordered.where(platform: REL_ME_PLATFORMS).map(&:link_url)

    urls.select { |url| valid_rel_me_url?(url) }
  end

  private

    def explicit_rel_me_links
      rel_me_links.to_s.lines.map(&:strip).reject(&:blank?).uniq
    end

    def rel_me_links_valid
      links = explicit_rel_me_links

      if links.size > MAX_REL_ME_LINKS
        errors.add(:rel_me_links, "can include at most #{MAX_REL_ME_LINKS} links")
      end

      links.each do |link|
        unless valid_rel_me_url?(link)
          errors.add(:rel_me_links, "includes an invalid URL: #{link}")
        end
      end
    end

    def valid_rel_me_url?(url)
      uri = URI.parse(url)
      case uri.scheme
      when "http", "https"
        uri.host.present?
      when "mailto"
        uri.to.match?(URI::MailTo::EMAIL_REGEXP)
      else
        false
      end
    rescue URI::Error
      false
    end
end
