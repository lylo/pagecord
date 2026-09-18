module App::AnalyticsHelper
  def format_number(number)
    number_with_delimiter(number.to_i)
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

  # Switching view keeps today in view when the viewed period contains it,
  # otherwise lands on the same position within the viewed period.
  def date_for_view(date, from, to)
    case to
    when "day"
      case from
      when "month" then current_period?(date, "month") ? Date.current : Date.new(date.year, date.month, [ Date.current.day, date.end_of_month.day ].min)
      when "year" then current_period?(date, "year") ? Date.current : date
      else date
      end
    when "month"
      case from
      when "day" then date.beginning_of_month
      when "year" then current_period?(date, "year") ? Date.current.beginning_of_month : Date.new(date.year, Date.current.month, 1)
      else date
      end
    when "year"
      from == "year" ? date : date.beginning_of_year
    end
  end

  def current_period?(date, view_type)
    case view_type
    when "day" then date.to_date == Date.current
    when "month" then date.beginning_of_month == Date.current.beginning_of_month
    when "year" then date.beginning_of_year == Date.current.beginning_of_year
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

    max_page_views = chart_data.map { |d| d[:unique_page_views] }.max
    return 10 if max_page_views.nil? || max_page_views == 0

    (max_page_views * 1.1).ceil
  end

  def chart_point_position(value, max_value, chart_width = 100)
    return 0 if max_value == 0
    (value.to_f / max_value * chart_width).round(2)
  end
end
