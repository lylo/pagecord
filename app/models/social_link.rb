class SocialLink < ApplicationRecord
  belongs_to :blog

  PLATFORMS = [ "Bluesky", "GitHub", "Instagram", "LinkedIn", "Spotify", "Threads", "TikTok", "Web", "X", "YouTube" ].sort

  validates :platform, presence: true, uniqueness: { scope: :blog_id }, inclusion: { in: PLATFORMS }
  validates :url, presence: true
  validate :validate_url_format

  private

    def validate_url_format
      uri = URI.parse(url)
      errors.add(:url, "must be HTTP or HTTPS") unless uri.scheme.in?(%w[http https])
    rescue URI::InvalidURIError
      errors.add(:url, "is not a valid URL")
    end
end
