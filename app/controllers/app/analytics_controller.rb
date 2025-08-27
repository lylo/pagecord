class App::AnalyticsController < AppController
  def index
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
    if params[:date].present?
      case @view_type
      when "day"
        Date.parse(params[:date])
      when "month"
        Date.parse("#{params[:date]}-01")
      when "year"
        Date.parse("#{params[:date]}-01-01")
      end
    else
      case @view_type
      when "day"
        Date.current
      when "month"
        Date.current.beginning_of_month
      when "year"
        Date.current.beginning_of_year
      end
    end
  rescue ArgumentError
    case @view_type
    when "day"
      Date.current
    when "month"
      Date.current.beginning_of_month
    when "year"
      Date.current.beginning_of_year
    end
  end

  def day_analytics(date)
    page_views = @blog.page_views.where(viewed_at: date.beginning_of_day..date.end_of_day)

    {
      unique_visitors: page_views.where(is_unique: true).count,
      total_visitors: page_views.count,
      date: date
    }
  end

  def month_analytics(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month
    page_views = @blog.page_views.where(viewed_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      unique_visitors: page_views.where(is_unique: true).count,
      total_visitors: page_views.count,
      date: date
    }
  end

  def year_analytics(date)
    start_date = date.beginning_of_year
    end_date = date.end_of_year
    page_views = @blog.page_views.where(viewed_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      unique_visitors: page_views.where(is_unique: true).count,
      total_visitors: page_views.count,
      date: date
    }
  end

  def day_chart_data(date)
    [ {
      date: date,
      unique_visitors: @analytics_data[:unique_visitors],
      total_visitors: @analytics_data[:total_visitors]
    } ]
  end

  def month_chart_data(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month

    # Create data points for every day, but group by 2-3 day periods for cleaner charts
    all_days = (start_date..end_date).to_a
    step_size = [all_days.length / 10, 1].max  # Aim for ~10 data points
    
    all_days.each_slice(step_size).map do |day_group|
      # Use the middle day of the group as the representative date
      representative_day = day_group[day_group.length / 2]
      
      # Sum up all page views for this group of days
      group_start = day_group.first.beginning_of_day
      group_end = day_group.last.end_of_day
      page_views = @blog.page_views.where(viewed_at: group_start..group_end)
      
      {
        date: representative_day,
        unique_visitors: page_views.where(is_unique: true).count,
        total_visitors: page_views.count
      }
    end
  end

  def year_chart_data(date)
    start_date = date.beginning_of_year

    (0..11).map do |month_offset|
      month_start = start_date.beginning_of_month + month_offset.months
      month_end = month_start.end_of_month
      page_views = @blog.page_views.where(viewed_at: month_start.beginning_of_day..month_end.end_of_day)

      {
        date: month_start,
        unique_visitors: page_views.where(is_unique: true).count,
        total_visitors: page_views.count
      }
    end
  end

  def path_popularity_data(view_type, date)
    date_range = case view_type
    when "day"
      date.beginning_of_day..date.end_of_day
    when "month"
      date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
    when "year"
      date.beginning_of_year.beginning_of_day..date.end_of_year.end_of_day
    end

    @blog.page_views
         .where(viewed_at: date_range, is_unique: true)
         .group(:path)
         .count
         .sort_by { |_, count| -count }
         .first(20)
  end
end
