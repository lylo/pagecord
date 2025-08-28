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
      user_timezone = Current.user.timezone || "UTC"
      
      current_month = Date.current.beginning_of_month

      if start_date >= current_month
        # Current month - use raw PageView data
        get_month_chart_data_from_raw_data(start_date, end_date, user_timezone)
      else
        # Previous month - use rollup data
        get_month_chart_data_from_rollups(start_date, end_date, user_timezone)
      end
    end

    def year_chart_data(date)
      start_date = date.beginning_of_year
      end_date = date.end_of_year
      user_timezone = Current.user.timezone || "UTC"
      cutoff_time = Date.current.beginning_of_month.beginning_of_day

      # Determine if we need rollup data, raw data, or both
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      if end_time_utc <= cutoff_time
        # Entire year is in rollup data - batch query all months at once
        get_year_chart_data_from_rollups(start_date, end_date, user_timezone)
      elsif start_time_utc > cutoff_time
        # Entire year is in raw data - batch query all months at once  
        get_year_chart_data_from_raw_data(start_date, end_date, user_timezone)
      else
        # Year spans both rollup and raw data - batch query both sources
        get_year_chart_data_mixed(start_date, end_date, user_timezone, cutoff_time)
      end
    end

    def path_popularity_data(view_type, date)
      user_timezone = Current.user.timezone || "UTC"

      # Convert user-timezone date to UTC time range for database query
      start_time, end_time = case view_type
      when "day"
        [
          date.in_time_zone(user_timezone).beginning_of_day.utc,
          date.in_time_zone(user_timezone).end_of_day.utc
        ]
      when "month"
        [
          date.beginning_of_month.in_time_zone(user_timezone).beginning_of_day.utc,
          date.end_of_month.in_time_zone(user_timezone).end_of_day.utc
        ]
      when "year"
        [
          date.beginning_of_year.in_time_zone(user_timezone).beginning_of_day.utc,
          date.end_of_year.in_time_zone(user_timezone).end_of_day.utc
        ]
      end

      cutoff_time = Date.current.beginning_of_month.beginning_of_day

      if end_time <= cutoff_time
        # Entire period is in rollup data - use rollups
        get_path_popularity_from_rollups(start_time, end_time)
      elsif start_time > cutoff_time
        # Entire period is in raw data - use PageViews
        get_path_popularity_from_pageviews(start_time, end_time)
      else
        # Period spans both rollup and raw data - combine both
        rollup_data = get_path_popularity_from_rollups(start_time, cutoff_time)
        pageview_data = get_path_popularity_from_pageviews(cutoff_time, end_time)

        # Combine and sort the results
        combined_data = {}
        rollup_data.each { |path, count| combined_data[path] = (combined_data[path] || 0) + count }
        pageview_data.each { |path, count| combined_data[path] = (combined_data[path] || 0) + count }

        combined_data.sort_by { |_, count| -count }.first(20)
      end
    end

    def get_path_popularity_from_pageviews(start_time, end_time)
      @blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .group(:path)
          .count
          .sort_by { |_, count| -count }
          .first(20)
    end

    def get_path_popularity_from_rollups(start_time, end_time)
      # Get rollup data grouped by post_id - filter by blog_id in dimensions
      rollup_data = Rollup.where(
        name: "unique_views_by_blog_post",
        time: start_time..end_time
      ).where("dimensions->>'blog_id' = ?", @blog.id.to_s)
      .group("dimensions->>'post_id'").sum(:value)

      # Batch load all posts to avoid N+1 queries
      post_ids = rollup_data.keys.compact.map(&:to_i)
      posts_by_id = Post.where(id: post_ids).index_by(&:id)

      # Convert post_ids to paths and sort
      path_data = {}
      rollup_data.each do |post_id_string, count|
        next if post_id_string.nil? || count == 0

        post_id = post_id_string.to_i
        post = posts_by_id[post_id]
        next unless post

        path = "/#{post.slug}"
        path_data[path] = (path_data[path] || 0) + count
      end

      path_data.sort_by { |_, count| -count }.first(20)
    end

    def get_year_chart_data_from_raw_data(start_date, end_date, user_timezone)
      # This method shouldn't be needed since we only store ~30 days of raw data
      # Current year will always span both rollup and raw data
      get_year_chart_data_mixed(start_date, end_date, user_timezone, Date.current.beginning_of_month.beginning_of_day)
    end

    def get_year_chart_data_mixed(start_date, end_date, user_timezone, cutoff_time)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      # Batch query rollup data for historical months
      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..cutoff_time,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog", 
        time: start_time_utc..cutoff_time,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      # Batch query raw data for recent period
      recent_page_views = @blog.page_views.where(viewed_at: cutoff_time..end_time_utc)
      
      # Group raw data by month in memory
      unique_views_by_month = Hash.new(0)
      total_views_by_month = Hash.new(0)

      recent_page_views.find_each do |page_view|
        month_key = page_view.viewed_at.in_time_zone(user_timezone).beginning_of_month
        total_views_by_month[month_key] += 1
        unique_views_by_month[month_key] += 1 if page_view.is_unique?
      end

      # Build chart data for each month, combining rollup and raw data
      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        if month_end_utc <= cutoff_time
          # Historical month - use rollup data
          unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i
          total_views = total_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i
        else
          # Recent month - use raw data (already grouped above)
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

    def get_month_chart_data_from_rollups(start_date, end_date, user_timezone)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      # Batch query both unique and total views for the entire month
      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      # Build chart data for each day
      (start_date..end_date).map do |day|
        day_start_utc = day.in_time_zone(user_timezone).beginning_of_day.utc
        day_end_utc = day.in_time_zone(user_timezone).end_of_day.utc

        # Sum all rollup values for this day
        unique_views = unique_rollups.select { |time, _| time >= day_start_utc && time <= day_end_utc }.values.sum.to_i
        total_views = total_rollups.select { |time, _| time >= day_start_utc && time <= day_end_utc }.values.sum.to_i

        {
          date: day,
          unique_page_views: unique_views,
          total_page_views: total_views
        }
      end
    end

    def get_month_chart_data_from_raw_data(start_date, end_date, user_timezone)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      # Batch query all page views for the entire month
      page_views = @blog.page_views.where(viewed_at: start_time_utc..end_time_utc)
      
      # Group by day and count in memory
      unique_views_by_day = Hash.new(0)
      total_views_by_day = Hash.new(0)

      page_views.find_each do |page_view|
        day_key = page_view.viewed_at.in_time_zone(user_timezone).to_date
        total_views_by_day[day_key] += 1
        unique_views_by_day[day_key] += 1 if page_view.is_unique?
      end

      # Build chart data for each day
      (start_date..end_date).map do |day|
        {
          date: day,
          unique_page_views: unique_views_by_day[day] || 0,
          total_page_views: total_views_by_day[day] || 0
        }
      end
    end


    def get_year_chart_data_from_rollups(start_date, end_date, user_timezone)
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      # Batch query both unique and total views for the entire year
      unique_rollups = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      total_rollups = Rollup.where(
        name: "total_views_by_blog",
        time: start_time_utc..end_time_utc,
        dimensions: { blog_id: @blog.id }
      ).group(:time).sum(:value)

      # Build chart data for each month
      (0..11).map do |month_offset|
        month_start = start_date.beginning_of_month + month_offset.months
        month_start_utc = month_start.in_time_zone(user_timezone).beginning_of_day.utc
        month_end_utc = month_start.end_of_month.in_time_zone(user_timezone).end_of_day.utc

        # Sum all rollup values for this month
        unique_views = unique_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i
        total_views = total_rollups.select { |time, _| time >= month_start_utc && time <= month_end_utc }.values.sum.to_i

        {
          date: month_start,
          unique_page_views: unique_views,
          total_page_views: total_views
        }
      end
    end

    def get_page_view_counts_for_period(start_date, end_date)
      # Convert user-timezone dates to UTC time ranges for database queries
      user_timezone = Current.user.timezone || "UTC"
      start_time_utc = start_date.in_time_zone(user_timezone).beginning_of_day.utc
      end_time_utc = end_date.in_time_zone(user_timezone).end_of_day.utc

      cutoff_time = Date.current.beginning_of_month.beginning_of_day

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
