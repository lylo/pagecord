class Analytics::Summary < Analytics::Base
  def analytics_data(view_type, date)
    case view_type
    when "day"
      day_analytics(date)
    when "month"
      month_analytics(date)
    when "year"
      year_analytics(date)
    end
  end

  def parse_date(view_type, date_param)
    if date_param.present?
      case view_type
      when "day"
        Date.parse(date_param).in_time_zone(user_timezone).to_date
      when "month"
        Date.parse("#{date_param}-01").in_time_zone(user_timezone).to_date
      when "year"
        Date.parse("#{date_param}-01-01").in_time_zone(user_timezone).to_date
      end
    else
      current_date_in_timezone = Time.now.in_time_zone(user_timezone).to_date
      case view_type
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
    case view_type
    when "day"
      current_date_in_timezone
    when "month"
      current_date_in_timezone.beginning_of_month
    when "year"
      current_date_in_timezone.beginning_of_year
    end
  end

  private

    def day_analytics(date)
      unique_page_views = page_view_counts_for_period(date, date)

      {
        unique_page_views: unique_page_views,
        date: date
      }
    end

    def month_analytics(date)
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      unique_page_views = page_view_counts_for_period(start_date, end_date)

      {
        unique_page_views: unique_page_views,
        date: date
      }
    end

    def year_analytics(date)
      start_date = date.beginning_of_year
      end_date = date.end_of_year
      unique_page_views = page_view_counts_for_period(start_date, end_date)

      {
        unique_page_views: unique_page_views,
        date: date
      }
    end

    def page_view_counts_for_period(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      if end_time_utc <= cutoff_time
        rollup_counts(start_time_utc, end_time_utc)
      elsif start_time_utc > cutoff_time
        raw_counts(start_time_utc, end_time_utc)
      else
        rollup_unique = rollup_counts(start_time_utc, cutoff_time)
        raw_unique = raw_counts(cutoff_time, end_time_utc)

        rollup_unique + raw_unique
      end
    end
end
