class App::AnalyticsController < AppController
  def index
    @view_type = params[:view_type] || "month"
    @date = Current.user.has_premium_access? ? summary.parse_date(@view_type, params[:date]) : Date.current

    if Current.user.has_premium_access?
      @analytics_data = summary.analytics_data(@view_type, @date)
      @chart_data = chart.chart_data(@view_type, @date, @analytics_data)
      @path_popularity = leaderboard.post_popularity_data(@view_type, @date)
      @referrer_data = referrers.referrer_data(@view_type, @date) if referrers_enabled?
      @country_data = countries.country_data(@view_type, @date) if countries_enabled?
    else
      # Demo data for non-premium users
      @analytics_data = demo_analytics_data
      @chart_data = demo_chart_data
      @path_popularity = demo_path_popularity_data
      @referrer_data = demo_referrer_data if referrers_enabled?
      @country_data = demo_country_data if countries_enabled?
    end
  end

  private

    def summary
      @summary ||= Analytics::Summary.new(@blog, user_timezone)
    end

    def chart
      @chart ||= Analytics::Chart.new(@blog, user_timezone)
    end

    def leaderboard
      @leaderboard ||= Analytics::Leaderboard.new(@blog, user_timezone)
    end

    def referrers
      @referrers ||= Analytics::Referrers.new(@blog, user_timezone)
    end

    def countries
      @countries ||= Analytics::Countries.new(@blog, user_timezone)
    end

    def user_timezone
      Current.user.timezone || "UTC"
    end

    def referrers_enabled?
      current_features.enabled?(:analytics_referrers)
    end

    def countries_enabled?
      current_features.enabled?(:analytics_countries)
    end

    def demo_analytics_data
      {
        unique_page_views: 1247,
        total_page_views: 1823,
        period_start: @date.beginning_of_month,
        period_end: @date.end_of_month
      }
    end

    def demo_chart_data
      days_in_month = @date.end_of_month.day
      data = []

      (1..days_in_month).each do |day|
        date = Date.new(@date.year, @date.month, day)
        break if date > Date.current

        base_views = 20 + rand(30)
        weekend_multiplier = date.wday.in?([ 0, 6 ]) ? 1.5 : 1.0
        views = (base_views * weekend_multiplier).round

        data << {
          date: date,  # Keep as Date object for chart compatibility
          unique_page_views: views
        }
      end

      data
    end

    def demo_path_popularity_data
      [
        { post_id: nil, count: 234, post_title: "Home Page", post: nil },
        { post_id: 1, count: 189, post_title: "Week Notes. ##{Date.current.strftime("%W, %B %Y")}", post: nil },
        { post_id: 2, count: 156, post_title: "Why I love using Pagecord", post: nil },
        { post_id: 3, count: 98, post_title: "Hello, world!", post: nil },
        { post_id: 4, count: 67, post_title: "About", post: nil }
      ]
    end

    def demo_referrer_data
      [
        { domain: nil, count: 412, friendly_name: "Direct", icon_path: "icons/person.svg", direct: true },
        { domain: "google.com", count: 287, friendly_name: "Google", icon_path: "icons/search.svg", direct: false },
        { domain: "x.com", count: 156, friendly_name: "X", icon_path: "icons/social/x.svg", direct: false },
        { domain: "news.ycombinator.com", count: 98, friendly_name: "Hacker News", icon_path: "icons/social/web.svg", direct: false },
        { domain: "reddit.com", count: 67, friendly_name: "Reddit", icon_path: "icons/social/reddit.svg", direct: false },
        { domain: "linkedin.com", count: 45, friendly_name: "LinkedIn", icon_path: "icons/social/linkedin.svg", direct: false }
      ]
    end

    def demo_country_data
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
end
