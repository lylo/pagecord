class SocialLink < ApplicationRecord
  belongs_to :blog

  PLATFORMS = [ "Bluesky", "Email", "GitHub", "Instagram", "LinkedIn", "Mastodon",
                "RSS", "Spotify", "Threads", "TikTok", "Web", "X", "YouTube" ].sort

  validates :platform, presence: true, uniqueness: { scope: :blog_id }, inclusion: { in: PLATFORMS }
  validates :url, presence: true
  validate :validate_url_format

  scope :mastodon, -> { where(platform: "Mastodon") }

  def email?
    platform == "Email"
  end

  private

    def validate_url_format
      return if email?

      uri = URI.parse(url)
      errors.add(:url, "must be HTTP or HTTPS") unless uri.scheme.in?(%w[http https])
    rescue URI::InvalidURIError
      errors.add(:url, "is not a valid URL")
    end
end
