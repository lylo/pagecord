class Admin::AnalyticsController < AdminController
  def index
    @view_type = params[:view_type] || "month"
    @date = parse_date(@view_type, params[:date])
    
    @top_posts = top_posts_with_view_counts
    @top_blogs = top_blogs_with_view_counts
    @top_blogs_by_subscribers = top_blogs_with_subscriber_counts
  end

  private

    def parse_date(view_type, date_param)
      if date_param.present?
        case view_type
        when "month"
          Date.parse("#{date_param}-01")
        when "year"
          Date.parse("#{date_param}-01-01")
        end
      else
        current_date = Date.current
        case view_type
        when "month"
          current_date.beginning_of_month
        when "year"
          current_date.beginning_of_year
        end
      end
    rescue ArgumentError
      current_date = Date.current
      case view_type
      when "month"
        current_date.beginning_of_month
      when "year"
        current_date.beginning_of_year
      end
    end

    def date_range_for_view_type
      case @view_type
      when "month"
        [@date.beginning_of_month.beginning_of_day, @date.end_of_month.end_of_day]
      when "year"
        [@date.beginning_of_year.beginning_of_day, @date.end_of_year.end_of_day]
      end
    end

    def top_posts_with_view_counts
      # Get all posts with their total view counts (PageViews + Rollups) for the selected period
      post_view_counts = {}
      start_time, end_time = date_range_for_view_type

      # Add PageView counts for the period
      PageView.joins(:post)
        .where(is_unique: true, viewed_at: start_time..end_time)
        .group("posts.id")
        .count
        .each { |post_id, count| post_view_counts[post_id] = count }

      # Add Rollup counts for the period
      Rollup.where(name: "unique_views_by_blog_post", time: start_time..end_time)
        .group("dimensions->>'post_id'")
        .sum(:value)
        .each do |post_id_string, count|
          next unless post_id_string
          post_id = post_id_string.to_i
          post_view_counts[post_id] = (post_view_counts[post_id] || 0) + count.to_i
        end

      # Get top 10 post IDs by view count
      top_post_ids = post_view_counts.sort_by { |_, count| -count }.first(10).map(&:first)

      # Fetch the actual Post objects with their blogs
      Post.includes(:blog)
        .where(id: top_post_ids)
        .map { |post| { post: post, count: post_view_counts[post.id] || 0 } }
        .sort_by { |item| -item[:count] }
    end

    def top_blogs_with_view_counts
      # Get all blogs with their total view counts (PageViews + Rollups) for the selected period
      blog_view_counts = {}
      start_time, end_time = date_range_for_view_type

      # Add PageView counts for the period
      PageView.joins(:blog)
        .where(is_unique: true, viewed_at: start_time..end_time)
        .group("blogs.id")
        .count
        .each { |blog_id, count| blog_view_counts[blog_id] = count }

      # Add Rollup counts for the period
      Rollup.where(name: "unique_views_by_blog", time: start_time..end_time)
        .group("dimensions->>'blog_id'")
        .sum(:value)
        .each do |blog_id_string, count|
          next unless blog_id_string
          blog_id = blog_id_string.to_i
          blog_view_counts[blog_id] = (blog_view_counts[blog_id] || 0) + count.to_i
        end

      # Get top 10 blog IDs by view count
      top_blog_ids = blog_view_counts.sort_by { |_, count| -count }.first(10).map(&:first)

      # Fetch the actual Blog objects
      blogs_with_counts = Blog.where(id: top_blog_ids)
        .map { |blog| { blog: blog, count: blog_view_counts[blog.id] || 0 } }
        .sort_by { |item| -item[:count] }
    end

    def top_blogs_with_subscriber_counts
      Blog.joins(:email_subscribers)
        .group(:id)
        .select("blogs.*, COUNT(email_subscribers.id) as subscriber_count")
        .having("COUNT(email_subscribers.id) > 0")
        .order("COUNT(email_subscribers.id) DESC")
        .limit(10)
        .map { |blog| { blog: blog, count: blog.subscriber_count } }
    end
end
