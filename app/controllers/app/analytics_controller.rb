class App::AnalyticsController < AppController
  def index
    redirect_to app_root_path unless current_features.enabled?(:analytics)

    @view_type = params[:view_type] || "month"
    @date = parse_date_param

    case @view_type
    when "day"
      @analytics_data = day_analytics(@date)
      @chart_data = day_chart_data(@date)
    when "month"
      @analytics_data = month_analytics(@date)
      @chart_data = month_chart_data(@date)
    when "year"
      @analytics_data = year_analytics(@date)
      @chart_data = year_chart_data(@date)
    end

    @path_popularity = path_popularity_data(@view_type, @date)
  end

  private

  def parse_date_param
    user_timezone = Current.user.timezone || "UTC"

    if params[:date].present?
      case @view_type
      when "day"
        Date.parse(params[:date]).in_time_zone(user_timezone).to_date
      when "month"
        Date.parse("#{params[:date]}-01").in_time_zone(user_timezone).to_date
      when "year"
        Date.parse("#{params[:date]}-01-01").in_time_zone(user_timezone).to_date
      end
    else
      current_date_in_timezone = Time.now.in_time_zone(user_timezone).to_date
      case @view_type
      when "day"
        current_date_in_timezone
      when "month"
        current_date_in_timezone.beginning_of_month
      when "year"
        current_date_in_timezone.beginning_of_year
      end
    end
  rescue ArgumentError
    current_date_in_timezone = Time.now.in_time_zone(user_timezone).to_date
    case @view_type
    when "day"
      current_date_in_timezone
    when "month"
      current_date_in_timezone.beginning_of_month
    when "year"
      current_date_in_timezone.beginning_of_year
    end
  end

  def day_analytics(date)
    unique_page_views, total_page_views = get_page_view_counts_for_period(date, date)

    {
      unique_page_views: unique_page_views,
      total_page_views: total_page_views,
      date: date
    }
  end

  def month_analytics(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month
    unique_page_views, total_page_views = get_page_view_counts_for_period(start_date, end_date)

    {
      unique_page_views: unique_page_views,
      total_page_views: total_page_views,
      date: date
    }
  end

  def year_analytics(date)
    start_date = date.beginning_of_year
    end_date = date.end_of_year
    unique_page_views, total_page_views = get_page_view_counts_for_period(start_date, end_date)

    {
      unique_page_views: unique_page_views,
      total_page_views: total_page_views,
      date: date
    }
  end

  def day_chart_data(date)
    [ {
      date: date,
      unique_page_views: @analytics_data[:unique_page_views],
      total_page_views: @analytics_data[:total_page_views]
    } ]
  end

  def month_chart_data(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month

    # Create one data point for each day of the month
    (start_date..end_date).map do |day|
      unique_page_views, total_page_views = get_page_view_counts_for_period(day, day)

      {
        date: day,
        unique_page_views: unique_page_views,
        total_page_views: total_page_views
      }
    end
  end

  def year_chart_data(date)
    start_date = date.beginning_of_year

    (0..11).map do |month_offset|
      month_start = start_date.beginning_of_month + month_offset.months
      month_end = month_start.end_of_month
      unique_page_views, total_page_views = get_page_view_counts_for_period(month_start, month_end)

      {
        date: month_start,
        unique_page_views: unique_page_views,
        total_page_views: total_page_views
      }
    end
  end

  def path_popularity_data(view_type, date)
    user_timezone = Current.user.timezone || "UTC"

    # Convert user-timezone date to UTC time range for database query
    date_range = case view_type
    when "day"
      start_time = date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time = date.in_time_zone(user_timezone).end_of_day.utc
      start_time..end_time
    when "month"
      start_time = date.beginning_of_month.in_time_zone(user_timezone).beginning_of_day.utc
      end_time = date.end_of_month.in_time_zone(user_timezone).end_of_day.utc
      start_time..end_time
    when "year"
      start_time = date.beginning_of_year.in_time_zone(user_timezone).beginning_of_day.utc
      end_time = date.end_of_year.in_time_zone(user_timezone).end_of_day.utc
      start_time..end_time
    end

    @blog.page_views
         .where(viewed_at: date_range, is_unique: true)
         .group(:path)
         .count
         .sort_by { |_, count| -count }
         .first(20)
  end

  private

  def get_page_view_counts_for_period(start_date, end_date)
    # Convert user-timezone dates to UTC time ranges for database queries
    user_timezone = Current.user.timezone || "UTC"
    start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
    end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

    cutoff_time = 30.days.ago.beginning_of_day

    # Split the period into rollup (old) and raw data (recent) periods
    if end_time_utc <= cutoff_time
      # Entire period is in rollup data
      get_rollup_counts(start_time_utc, end_time_utc)
    elsif start_time_utc > cutoff_time
      # Entire period is in raw data
      get_raw_counts(start_time_utc, end_time_utc)
    else
      # Period spans both rollup and raw data
      rollup_unique, rollup_total = get_rollup_counts(start_time_utc, cutoff_time)
      raw_unique, raw_total = get_raw_counts(cutoff_time, end_time_utc)

      [ rollup_unique + raw_unique, rollup_total + raw_total ]
    end
  end

  def get_rollup_counts(start_time, end_time)
    # Query rollup data for the blog
    unique_count = Rollup.where(
      name: "unique_views_by_blog",
      time: start_time..end_time,
      dimensions: { blog_id: @blog.id }
    ).sum(:value).to_i

    total_count = Rollup.where(
      name: "total_views_by_blog",
      time: start_time..end_time,
      dimensions: { blog_id: @blog.id }
    ).sum(:value).to_i

    [ unique_count, total_count ]
  end

  def get_raw_counts(start_time, end_time)
    page_views = @blog.page_views.where(viewed_at: start_time..end_time)

    unique_count = page_views.where(is_unique: true).count
    total_count = page_views.count

    [ unique_count, total_count ]
  end
end
