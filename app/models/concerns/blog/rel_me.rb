module Blog::RelMe
  extend ActiveSupport::Concern

  MAX_REL_ME_LINKS = 10

  included do
    validate :rel_me_links_valid
  end

  # Explicit identity links (one per line) combined with social navigation
  # item links. RSS (the blog's own feed) and Web (an arbitrary site, not
  # necessarily the author's) are not inferred. Emitted as <link rel="me">
  # in the blog head.
  def rel_me_urls
    urls = explicit_rel_me_links +
      social_navigation_items.ordered.where.not(platform: %w[RSS Web]).map(&:link_url)

    urls.uniq.select { |url| valid_rel_me_url?(url) }
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
