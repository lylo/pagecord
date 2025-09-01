class Analytics::Base
  RANGES = {
    "day" => ->(d, tz) { [
      d.in_time_zone(tz).beginning_of_day.utc,
      d.in_time_zone(tz).end_of_day.utc
    ] },
    "month" => ->(d, tz) { [
      d.beginning_of_month.in_time_zone(tz).beginning_of_day.utc,
      d.end_of_month.in_time_zone(tz).end_of_day.utc
    ] },
    "year" => ->(d, tz) { [
      d.beginning_of_year.in_time_zone(tz).beginning_of_day.utc,
      d.end_of_year.in_time_zone(tz).end_of_day.utc
    ] }
  }.freeze

  attr_reader :blog, :user_timezone

  def initialize(blog, user_timezone = nil)
    @blog = blog
    @user_timezone = user_timezone || "UTC"
  end

  protected

    def cutoff_time
      if Rollup.exists?
        Date.current.prev_month.beginning_of_month.beginning_of_day
      else
        Date.new(1900, 1, 1)
      end
    end

    def time_range_for_view_type(view_type, date)
      RANGES.fetch(view_type).call(date, user_timezone)
    end

    def rollup_counts(start_time, end_time)
      unique_count = Rollup.where(
        name: "unique_views_by_blog",
        time: start_time..end_time,
        dimensions: { blog_id: blog.id }
      ).sum(:value).to_i

      total_count = Rollup.where(
        name: "total_views_by_blog",
        time: start_time..end_time,
        dimensions: { blog_id: blog.id }
      ).sum(:value).to_i

      [ unique_count, total_count ]
    end

    def raw_counts(start_time, end_time)
      page_views = blog.page_views.where(viewed_at: start_time..end_time)

      unique_count = page_views.where(is_unique: true).count
      total_count = page_views.count

      [ unique_count, total_count ]
    end
end
