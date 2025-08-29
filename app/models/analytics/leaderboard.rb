class Analytics::Leaderboard < Analytics::Base
  # Returns array of hashes: [{ post_id: 123, count: 45, post_title: "My Post" }, { post_id: nil, count: 12, post_title: "Home Page" }]
  # post_id is nil for homepage views, integer for specific posts
  def post_popularity_data(view_type, date)
    start_time, end_time = time_range_for_view_type(view_type, date)

    data = if end_time <= cutoff_time
      post_popularity_from_rollups(start_time, end_time)
    elsif start_time > cutoff_time
      post_popularity_from_page_views(start_time, end_time)
    else
      combine_rollup_and_pageview_data(start_time, end_time)
    end

    add_post_data(data)
  end

  private

    def post_popularity_from_page_views(start_time, end_time)
      blog.page_views
          .where(viewed_at: start_time..end_time, is_unique: true)
          .group(:post_id)
          .count
          .sort_by { |_, count| -count }
          .first(20)
          .map { |post_id, count| { post_id: post_id, count: count } }
    end

    def post_popularity_from_rollups(start_time, end_time)
      Rollup.where(
        name: "unique_views_by_blog_post",
        time: start_time..end_time
      ).where("dimensions->>'blog_id' = ?", blog.id.to_s)
       .group("dimensions->>'post_id'").sum(:value)
       .sort_by { |_, count| -count }
       .first(20)
       .map { |post_id_string, count| { post_id: post_id_string&.to_i, count: count } }
    end

    def combine_rollup_and_pageview_data(start_time, end_time)
      rollup_data = post_popularity_from_rollups(start_time, cutoff_time)
      pageview_data = post_popularity_from_page_views(cutoff_time, end_time)

      combined_data = {}
      rollup_data.each { |item| combined_data[item[:post_id]] = (combined_data[item[:post_id]] || 0) + item[:count] }
      pageview_data.each { |item| combined_data[item[:post_id]] = (combined_data[item[:post_id]] || 0) + item[:count] }

      combined_data.sort_by { |_, count| -count }
                  .first(20)
                  .map { |post_id, count| { post_id: post_id, count: count } }
    end

    def add_post_data(data)
      post_ids = data.map { |item| item[:post_id] }.compact
      posts_by_id = Post.includes(:blog, :rich_text_content).where(id: post_ids, blog: blog).index_by(&:id)

      data.map do |item|
        post_id = item[:post_id]

        if post_id.nil?
          item.merge(post_title: "Home Page", post: nil)
        else
          post = posts_by_id[post_id]
          item.merge(
            post_title: post&.display_title || "Unknown Post",
            post: post
          )
        end
      end
    end
end
