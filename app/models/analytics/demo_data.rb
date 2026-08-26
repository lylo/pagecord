class Analytics::DemoData
  def initialize(date)
    @date = date
  end

  def analytics_data
    {
      unique_page_views: 1247,
      total_page_views: 1823,
      period_start: date.beginning_of_month,
      period_end: date.end_of_month
    }
  end

  def chart_data
    (1..date.end_of_month.day).filter_map do |day|
      day_date = Date.new(date.year, date.month, day)
      next if day_date > Date.current

      base_views = 20 + rand(30)
      weekend_multiplier = day_date.wday.in?([ 0, 6 ]) ? 1.5 : 1.0

      { date: day_date, unique_page_views: (base_views * weekend_multiplier).round }
    end
  end

  def path_popularity_data
    [
      { post_id: nil, count: 234, post_title: "Home Page", post: nil },
      { post_id: 1, count: 189, post_title: "Week Notes. ##{Date.current.strftime("%W, %B %Y")}", post: nil },
      { post_id: 2, count: 156, post_title: "Why I love using Pagecord", post: nil },
      { post_id: 3, count: 98, post_title: "Hello, world!", post: nil },
      { post_id: 4, count: 67, post_title: "About", post: nil }
    ]
  end

  def referrer_data
    [
      { domain: nil, count: 412, friendly_name: "Direct", icon_path: "icons/person.svg", direct: true },
      { domain: "google.com", count: 287, friendly_name: "Google", icon_path: "icons/search.svg", direct: false },
      { domain: "x.com", count: 156, friendly_name: "X", icon_path: "icons/social/x.svg", direct: false },
      { domain: "news.ycombinator.com", count: 98, friendly_name: "Hacker News", icon_path: "icons/social/web.svg", direct: false },
      { domain: "reddit.com", count: 67, friendly_name: "Reddit", icon_path: "icons/social/reddit.svg", direct: false },
      { domain: "linkedin.com", count: 45, friendly_name: "LinkedIn", icon_path: "icons/social/linkedin.svg", direct: false }
    ]
  end

  def country_data
    [
      { code: "US", count: 523, name: "United States", flag: "\u{1F1FA}\u{1F1F8}" },
      { code: "GB", count: 187, name: "United Kingdom", flag: "\u{1F1EC}\u{1F1E7}" },
      { code: "DE", count: 134, name: "Germany", flag: "\u{1F1E9}\u{1F1EA}" },
      { code: "CA", count: 98, name: "Canada", flag: "\u{1F1E8}\u{1F1E6}" },
      { code: "FR", count: 76, name: "France", flag: "\u{1F1EB}\u{1F1F7}" },
      { code: "AU", count: 54, name: "Australia", flag: "\u{1F1E6}\u{1F1FA}" },
      { code: "NL", count: 43, name: "Netherlands", flag: "\u{1F1F3}\u{1F1F1}" },
      { code: "JP", count: 38, name: "Japan", flag: "\u{1F1EF}\u{1F1F5}" }
    ]
  end

  private

    attr_reader :date
end
