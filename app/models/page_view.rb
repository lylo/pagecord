class PageView < ApplicationRecord
  belongs_to :blog
  belongs_to :post, optional: true  # Optional for index page views

  validates :path, :visitor_hash, :viewed_at, presence: true

  scope :for_posts, -> { where.not(post_id: nil) }
  scope :for_index, -> { where(post_id: nil) }
  scope :unique_views, -> { where(is_unique: true) }
  scope :total_views, -> { all }
  scope :recent, ->(days = 30) { where(viewed_at: days.days.ago..) }

  def self.generate_visitor_hash(ip, user_agent, date = Date.current)
    Digest::SHA256.hexdigest("#{ip}#{user_agent}#{date}")
  end

  def self.bot_user_agent?(user_agent)
    return true if user_agent.blank?

    bot_patterns = [
      /bot/i, /spider/i, /crawler/i, /scraper/i,
      /mastodon/i, /fediverse/i, /pleroma/i,
      /facebook/i, /twitter/i, /linkedin/i,
      /discord/i, /slack/i, /telegram/i,
      /preview/i, /fetch/i, /scanner/i
    ]

    bot_patterns.any? { |pattern| user_agent.match?(pattern) }
  end

  def self.track_view(blog:, post: nil, request:)
    return if bot_user_agent?(request.user_agent)

    ip = request.remote_ip
    user_agent = request.user_agent
    today = Date.current

    visitor_hash = generate_visitor_hash(ip, user_agent, today)

    # Check if this is a unique view for this visitor/post/day
    existing_view = where(
      blog: blog,
      post: post,
      visitor_hash: visitor_hash,
      viewed_at: today.beginning_of_day..today.end_of_day
    ).exists?

    create!(
      blog: blog,
      post: post,
      path: request.fullpath,
      visitor_hash: visitor_hash,
      ip_address: ip,
      user_agent: user_agent,
      referrer: request.referrer,
      country: request.headers["CF-IPCountry"],
      is_unique: !existing_view,
      viewed_at: Time.current
    )
  end

  def index_page_view?
    post_id.nil?
  end

  def post_view?
    post_id.present?
  end

  # Set rollup column for this model
  self.rollup_column = :viewed_at
end
