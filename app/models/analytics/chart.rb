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
        unique_page_views: analytics_data[:unique_page_views]
      } ]
    end

    def month_chart_data(date)
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc

      if start_time_utc >= cutoff_time
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

      (start_date..end_date).map do |day|
        day_start_utc = day.in_time_zone(user_timezone).beginning_of_day.utc
        day_end_utc = day.in_time_zone(user_timezone).end_of_day.utc

        unique_views = unique_rollups.select { |time, _| time >= day_start_utc && time <= day_end_utc }.values.sum.to_i

        {
          date: day,
          unique_page_views: unique_views
        }
      end
    end

    def month_chart_data_from_raw_data(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      unique_views_by_day = page_view_counts_by_day(start_time_utc, end_time_utc)

      (start_date..end_date).map do |day|
        {
          date: day,
          unique_page_views: unique_views_by_day[day] || 0
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

      unique_views_by_month = page_view_counts_by_month([ start_time_utc, cutoff_time ].max, end_time_utc)

      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        # Use rollups if month ended more than 30 days ago AND rollups exist for this month
        rollup_unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i

        if month_end_utc <= cutoff_time && rollup_unique_views > 0
          unique_views = rollup_unique_views
        else
          unique_views = unique_views_by_month[month_start] || 0
        end

        {
          date: month_start,
          unique_page_views: unique_views
        }
      end
    end

    def page_view_counts_by_day(start_time, end_time)
      page_view_counts_grouped_by(
        "DATE(page_views.viewed_at AT TIME ZONE 'UTC' AT TIME ZONE ?)",
        start_time,
        end_time
      )
    end

    def page_view_counts_by_month(start_time, end_time)
      page_view_counts_grouped_by(
        "DATE_TRUNC('month', page_views.viewed_at AT TIME ZONE 'UTC' AT TIME ZONE ?)::date",
        start_time,
        end_time
      )
    end

    def page_view_counts_grouped_by(group_sql, start_time, end_time)
      group_expression = Arel.sql(PageView.sanitize_sql_array([ group_sql, database_timezone ]))

      blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .group(group_expression)
          .count
          .transform_keys(&:to_date)
    end

    def database_timezone
      ActiveSupport::TimeZone[user_timezone]&.tzinfo&.name || user_timezone
    end

    def year_chart_data_from_rollups(start_date, end_date)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: blog.id }
      ).group(:time).sum(:value)

      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i

        {
          date: month_start,
          unique_page_views: unique_views
        }
      end
    end
end
