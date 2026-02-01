class Analytics::Referrers < Analytics::Base
  # Returns array of hashes: [{ domain: "google.com", count: 45, friendly_name: "Google", icon_path: "icons/search.svg" }]
  def referrer_data(view_type, date, limit: 10)
    start_time, end_time = time_range_for_view_type(view_type, date)

    data = if end_time <= cutoff_time
      referrers_from_rollups(start_time, end_time)
    elsif start_time > cutoff_time
      referrers_from_page_views(start_time, end_time)
    else
      combine_rollup_and_pageview_data(start_time, end_time)
    end

    add_referrer_metadata(data.first(limit))
  end

  private

    def referrers_from_page_views(start_time, end_time)
      blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .group(:referrer_domain)
          .count
          .sort_by { |_, count| -count }
          .map { |domain, count| { domain: domain, count: count } }
    end

    def referrers_from_rollups(start_time, end_time)
      Rollup.where(
        name: "unique_views_by_blog_referrer",
        time: start_time..end_time
      ).where("dimensions->>'blog_id' = ?", blog.id.to_s)
       .group("dimensions->>'referrer_domain'").sum(:value)
       .sort_by { |_, count| -count }
       .map { |domain, count| { domain: domain, count: count } }
    end

    def combine_rollup_and_pageview_data(start_time, end_time)
      rollup_data = referrers_from_rollups(start_time, cutoff_time)
      pageview_data = referrers_from_page_views(cutoff_time, end_time)

      combined_data = {}
      rollup_data.each { |item| combined_data[item[:domain]] = (combined_data[item[:domain]] || 0) + item[:count] }
      pageview_data.each { |item| combined_data[item[:domain]] = (combined_data[item[:domain]] || 0) + item[:count] }

      combined_data.sort_by { |_, count| -count }
                   .map { |domain, count| { domain: domain, count: count } }
    end

    def add_referrer_metadata(data)
      data.map do |item|
        referrer = Referrer.new(item[:domain] ? "https://#{item[:domain]}" : nil)
        item.merge(
          friendly_name: referrer.friendly_name,
          icon_path: referrer.icon_path,
          direct: referrer.direct?
        )
      end
    end
end
