class SocialLink < ApplicationRecord
  belongs_to :blog

  PLATFORMS = [ "Bluesky", "GitHub", "Instagram", "LinkedIn", "Spotify", "Threads", "TikTok", "X", "YouTube" ].sort

  validates :platform, presence: true, uniqueness: { scope: :blog_id }, inclusion: { in: PLATFORMS }
  validates :url, presence: true
end
