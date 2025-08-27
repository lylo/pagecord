class PageView < ApplicationRecord
  belongs_to :blog
  belongs_to :post, optional: true  # Optional for index page views

  validates :visitor_hash, :viewed_at, presence: true

  self.rollup_column = :viewed_at

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

  def self.track(blog:, post: nil, request:, path: nil, referrer: nil)
    return if bot_user_agent?(request.user_agent)

    ip = request.remote_ip
    user_agent = request.user_agent
    today = Date.current

    visitor_hash = generate_visitor_hash(ip, user_agent, today)

    parsed_path, query_string = parse_path_and_query(path)

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
      path: parsed_path,
      query_string: query_string,
      visitor_hash: visitor_hash,
      ip_address: ip,
      user_agent: user_agent,
      referrer: referrer,
      country: request.headers["CF-IPCountry"],
      is_unique: !existing_view,
      viewed_at: Time.current
    )
  end

  private

  def self.parse_path_and_query(full_path)
    return [ nil, nil ] if full_path.blank?

    uri = URI.parse(full_path) rescue nil
    return [ full_path, nil ] if uri.nil?

    clean_path = uri.path.presence || "/"
    query_string = uri.query.presence

    [ clean_path, query_string ]
  end
end
