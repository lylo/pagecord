class Analytics::Countries < Analytics::Base
  # Returns array of hashes: [{ code: "US", count: 45, name: "United States", flag: "🇺🇸" }]
  def country_data(view_type, date, limit: 10)
    start_time, end_time = time_range_for_view_type(view_type, date)

    data = if end_time <= cutoff_time
      countries_from_rollups(start_time, end_time)
    elsif start_time > cutoff_time
      countries_from_page_views(start_time, end_time)
    else
      combine_rollup_and_pageview_data(start_time, end_time)
    end

    add_country_metadata(data.first(limit))
  end

  private

    def countries_from_page_views(start_time, end_time)
      blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .where.not(country: nil)
          .group(:country)
          .count
          .sort_by { |_, count| -count }
          .map { |code, count| { code: code, count: count } }
    end

    def countries_from_rollups(start_time, end_time)
      Rollup.where(
        name: "unique_views_by_blog_country",
        time: start_time..end_time
      ).where("dimensions->>'blog_id' = ?", blog.id.to_s)
       .where("dimensions->>'country' IS NOT NULL")
       .group("dimensions->>'country'").sum(:value)
       .sort_by { |_, count| -count }
       .map { |code, count| { code: code, count: count } }
    end

    def combine_rollup_and_pageview_data(start_time, end_time)
      rollup_data = countries_from_rollups(start_time, cutoff_time)
      pageview_data = countries_from_page_views(cutoff_time, end_time)

      combined_data = {}
      rollup_data.each { |item| combined_data[item[:code]] = (combined_data[item[:code]] || 0) + item[:count] }
      pageview_data.each { |item| combined_data[item[:code]] = (combined_data[item[:code]] || 0) + item[:count] }

      combined_data.sort_by { |_, count| -count }
                   .map { |code, count| { code: code, count: count } }
    end

    def add_country_metadata(data)
      data.map do |item|
        country = Country.new(item[:code])
        item.merge(
          name: country.name,
          flag: country.flag
        )
      end
    end
end
