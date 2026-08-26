class App::AnalyticsController < App::BaseController
  before_action :redirect_if_metrics_hidden

  def index
    @view_type = params[:view_type] || "month"
    @date = Current.user.has_premium_access? ? summary.parse_date(@view_type, params[:date]) : Date.current

    if Current.user.has_premium_access?
      @analytics_data = summary.analytics_data(@view_type, @date)
      @chart_data = chart.chart_data(@view_type, @date, @analytics_data)
      @path_popularity = leaderboard.post_popularity_data(@view_type, @date)
      @referrer_data = referrers.referrer_data(@view_type, @date)
      @country_data = countries.country_data(@view_type, @date)
    else
      demo = Analytics::DemoData.new(@date)

      @analytics_data = demo.analytics_data
      @chart_data = demo.chart_data
      @path_popularity = demo.path_popularity_data
      @referrer_data = demo.referrer_data
      @country_data = demo.country_data
    end
  end

  private

    def redirect_if_metrics_hidden
      redirect_to app_root_path unless @blog.show_metrics?
    end

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
end
