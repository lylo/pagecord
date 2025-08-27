module App::AnalyticsHelper
  def format_number(number)
    number_with_delimiter(number)
  end

  def format_date_for_view_type(date, view_type)
    case view_type
    when "day"
      date.strftime("%B %d, %Y")
    when "month"
      date.strftime("%B %Y")
    when "year"
      date.strftime("%Y")
    end
  end

  def nav_path_for_date(view_type, date)
    case view_type
    when "day"
      app_analytics_path(view_type: view_type, date: date.strftime("%Y-%m-%d"))
    when "month"
      app_analytics_path(view_type: view_type, date: date.strftime("%Y-%m"))
    when "year"
      app_analytics_path(view_type: view_type, date: date.strftime("%Y"))
    end
  end

  def previous_date(date, view_type)
    case view_type
    when "day"
      date - 1.day
    when "month"
      date - 1.month
    when "year"
      date - 1.year
    end
  end

  def next_date(date, view_type)
    case view_type
    when "day"
      date + 1.day
    when "month"
      date + 1.month
    when "year"
      date + 1.year
    end
  end

  def chart_max_value(chart_data)
    return 10 if chart_data.empty?

    max_visitors = chart_data.map { |d| [ d[:unique_visitors], d[:total_visitors] ] }.flatten.max
    return 10 if max_visitors.nil? || max_visitors == 0
    
    (max_visitors * 1.1).ceil
  end

  def chart_point_position(value, max_value, chart_width = 100)
    return 0 if max_value == 0
    (value.to_f / max_value * chart_width).round(2)
  end
end
