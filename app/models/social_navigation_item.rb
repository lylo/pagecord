class SocialNavigationItem < NavigationItem
  PLATFORMS = [ "Bluesky", "Email", "GitHub", "Instagram", "LinkedIn", "Mastodon",
                "RSS", "Spotify", "Threads", "TikTok", "Web", "X", "YouTube" ].sort

  validates :platform, presence: true, inclusion: { in: PLATFORMS }
  validates :url, presence: true
  validate :validate_url_format

  before_validation :set_label_from_platform, if: -> { platform.present? && label.blank? }

  def link_url
    email? ? "mailto:#{url}" : url
  end

  def email?
    platform == "Email"
  end

  private

    def validate_url_format
      if email?
        unless url =~ URI::MailTo::EMAIL_REGEXP
          errors.add(:url, "must be a valid email address")
        end
      else
        uri = URI.parse(url)
        errors.add(:url, "must be HTTP or HTTPS") unless uri.scheme.in?(%w[http https])
      end
    rescue URI::InvalidURIError
      errors.add(:url, "is not a valid URL")
    end

    def set_label_from_platform
      self.label = platform
    end
end
