class App::AnalyticsController < AppController
  def index
    @view_type = params[:view_type] || "month"
    @date = Current.user.subscribed? || Current.user.on_trial? ? summary.parse_date(@view_type, params[:date]) : Date.current

    if Current.user.subscribed? || Current.user.on_trial?
      @analytics_data = summary.analytics_data(@view_type, @date)
      @chart_data = chart.chart_data(@view_type, @date, @analytics_data)
      @path_popularity = leaderboard.post_popularity_data(@view_type, @date)
    else
      # Demo data for non-premium users
      @analytics_data = demo_analytics_data
      @chart_data = demo_chart_data
      @path_popularity = demo_path_popularity_data
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

    def user_timezone
      Current.user.timezone || "UTC"
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
        { post_id: 3, count: 98, post_title: "Hello, world! 👋", post: nil },
        { post_id: 4, count: 67, post_title: "About", post: nil }
      ]
    end
end
