class SocialLink < ApplicationRecord
  belongs_to :blog

  PLATFORMS = [ "X", "Instagram", "Bluesky", "Threads", "YouTube" ].sort

  validates :platform, presence: true, uniqueness: { scope: :blog_id }, inclusion: { in: PLATFORMS }
  validates :url, presence: true
end
