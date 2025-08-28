class Analytics::Leaderboard < Analytics::Base
  def path_popularity_data(view_type, date)
    start_time, end_time = time_range_for_view_type(view_type, date)

    if end_time <= cutoff_time
      path_popularity_from_rollups(start_time, end_time)
    elsif start_time > cutoff_time
      path_popularity_from_page_views(start_time, end_time)
    else
      combine_rollup_and_pageview_data(start_time, end_time)
    end
  end

  private

    def path_popularity_from_page_views(start_time, end_time)
      blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .group(:path)
          .count
          .sort_by { |_, count| -count }
          .first(20)
          .map { |path, count| { path: path, count: count } }
    end

    def path_popularity_from_rollups(start_time, end_time)
      rollup_data = Rollup.where(
        name: "unique_views_by_blog_post",
        time: start_time..end_time
      ).where("dimensions->>'blog_id' = ?", blog.id.to_s)
      .group("dimensions->>'post_id'").sum(:value)

      post_ids = rollup_data.keys.compact.map(&:to_i)
      posts_by_id = Post.where(id: post_ids).index_by(&:id)

      path_data = {}
      rollup_data.each do |post_id_string, count|
        next if post_id_string.nil? || count == 0

        post_id = post_id_string.to_i
        post = posts_by_id[post_id]
        next unless post

        path = "/#{post.slug}"
        path_data[path] = (path_data[path] || 0) + count
      end

      path_data.sort_by { |_, count| -count }
              .first(20)
              .map { |path, count| { path: path, count: count } }
    end

    def combine_rollup_and_pageview_data(start_time, end_time)
      rollup_data = path_popularity_from_rollups(start_time, cutoff_time)
      pageview_data = path_popularity_from_page_views(cutoff_time, end_time)

      combined_data = {}
      rollup_data.each { |item| combined_data[item[:path]] = (combined_data[item[:path]] || 0) + item[:count] }
      pageview_data.each { |item| combined_data[item[:path]] = (combined_data[item[:path]] || 0) + item[:count] }

      combined_data.sort_by { |_, count| -count }
                  .first(20)
                  .map { |path, count| { path: path, count: count } }
    end
end
