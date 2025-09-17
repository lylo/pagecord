class App::AnalyticsController < AppController
  def index
    @view_type = params[:view_type] || "month"
    @date = summary.parse_date(@view_type, params[:date])

    @analytics_data = summary.analytics_data(@view_type, @date)
    @chart_data = chart.chart_data(@view_type, @date, @analytics_data)
    @path_popularity = leaderboard.post_popularity_data(@view_type, @date)
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
end
