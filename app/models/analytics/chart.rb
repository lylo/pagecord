class Analytics::Chart < Analytics::Base
  def chart_data(view_type, date, analytics_data)
    case view_type
    when "day"
      day_chart_data(date, analytics_data)
    when "month"
      month_chart_data(date)
    when "year"
      year_chart_data(date)
    end
  end

  private

    def day_chart_data(date, analytics_data)
      [ {
        date: date,
        unique_page_views: analytics_data[:unique_page_views],
        total_page_views: analytics_data[:total_page_views]
      } ]
    end

    def month_chart_data(date)
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      current_month = Date.current.beginning_of_month

      if start_date >= current_month
        month_chart_data_from_raw_data(start_date, end_date)
      else
        month_chart_data_from_rollups(start_date, end_date)
      end
    end

    def year_chart_data(date)
      start_date = date.beginning_of_year
      end_date = date.end_of_year

      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      if end_time_utc <= cutoff_time
        year_chart_data_from_rollups(start_date, end_date)
      elsif start_time_utc > cutoff_time
        year_chart_data_from_raw_data(start_date, end_date)
      else
        year_chart_data_mixed(start_date, end_date)
      end
    end

    def month_chart_data_from_rollups(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      (start_date..end_date).map do |day|
        day_start_utc = day.in_time_zone(user_timezone).beginning_of_day.utc
        day_end_utc = day.in_time_zone(user_timezone).end_of_day.utc

        unique_views = unique_rollups.select { |time, _| time >= day_start_utc && time <= day_end_utc }.values.sum.to_i
        total_views = total_rollups.select { |time, _| time >= day_start_utc && time <= day_end_utc }.values.sum.to_i

        {
          date: day,
          unique_page_views: unique_views,
          total_page_views: total_views
        }
      end
    end

    def month_chart_data_from_raw_data(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      page_views = blog.page_views.where(viewed_at: start_time_utc..end_time_utc)

      unique_views_by_day = Hash.new(0)
      total_views_by_day = Hash.new(0)

      page_views.find_each do |page_view|
        day_key = page_view.viewed_at.in_time_zone(user_timezone).to_date
        total_views_by_day[day_key] += 1
        unique_views_by_day[day_key] += 1 if page_view.is_unique?
      end

      (start_date..end_date).map do |day|
        {
          date: day,
          unique_page_views: unique_views_by_day[day] || 0,
          total_page_views: total_views_by_day[day] || 0
        }
      end
    end

    def year_chart_data_from_raw_data(start_date, end_date)
      year_chart_data_mixed(start_date, end_date)
    end

    def year_chart_data_mixed(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..cutoff_time,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog",
        time: start_time_utc..cutoff_time,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      # Get raw page views for the entire year to handle months without rollups
      all_page_views = blog.page_views.where(viewed_at: start_time_utc..end_time_utc)

      unique_views_by_month = Hash.new(0)
      total_views_by_month = Hash.new(0)

      all_page_views.find_each do |page_view|
        month_key = page_view.viewed_at.in_time_zone(user_timezone).beginning_of_month.to_date
        total_views_by_month[month_key] += 1
        unique_views_by_month[month_key] += 1 if page_view.is_unique?
      end

      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        # Use rollups if month ended more than 30 days ago AND rollups exist for this month
        rollup_unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i
        rollup_total_views = total_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i

        if month_end_utc <= cutoff_time && (rollup_unique_views > 0 || rollup_total_views > 0)
          unique_views = rollup_unique_views
          total_views = rollup_total_views
        else
          unique_views = unique_views_by_month[month_start] || 0
          total_views = total_views_by_month[month_start] || 0
        end

        {
          date: month_start,
          unique_page_views: unique_views,
          total_page_views: total_views
        }
      end
    end

    def year_chart_data_from_rollups(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i
        total_views = total_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i

        {
          date: month_start,
          unique_page_views: unique_views,
          total_page_views: total_views
        }
      end
    end
end
