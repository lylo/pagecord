class Admin::AnalyticsController < AdminController
  def index
    @top_posts = top_posts_with_view_counts
    @top_blogs = top_blogs_with_view_counts
    @top_blogs_by_subscribers = top_blogs_with_subscriber_counts
  end

  private

    def top_posts_with_view_counts
      # Get all posts with their total view counts (PageViews + Rollups)
      post_view_counts = {}

      # Add recent PageView counts
      PageView.joins(:post)
        .group("posts.id")
        .count
        .each { |post_id, count| post_view_counts[post_id] = count }

      # Add historical Rollup counts
      Rollup.where(name: "unique_views_by_blog_post")
        .group("dimensions->>'post_id'")
        .sum(:value)
        .each do |post_id_string, count|
          next unless post_id_string
          post_id = post_id_string.to_i
          post_view_counts[post_id] = (post_view_counts[post_id] || 0) + count
        end

      # Get top 10 post IDs by view count
      top_post_ids = post_view_counts.sort_by { |_, count| -count }.first(10).map(&:first)

      # Fetch the actual Post objects with their blogs
      posts_with_counts = Post.includes(:blog)
        .where(id: top_post_ids)
        .map { |post| { post: post, count: post_view_counts[post.id] || 0 } }
        .sort_by { |item| -item[:count] }
    end

    def top_blogs_with_view_counts
      # Get all blogs with their total view counts (PageViews + Rollups)
      blog_view_counts = {}

      # Add recent PageView counts
      PageView.joins(:blog)
        .group("blogs.id")
        .count
        .each { |blog_id, count| blog_view_counts[blog_id] = count }

      # Add historical Rollup counts
      Rollup.where(name: "unique_views_by_blog")
        .group("dimensions->>'blog_id'")
        .sum(:value)
        .each do |blog_id_string, count|
          next unless blog_id_string
          blog_id = blog_id_string.to_i
          blog_view_counts[blog_id] = (blog_view_counts[blog_id] || 0) + count
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
        .select('blogs.*, COUNT(email_subscribers.id) as subscriber_count')
        .having('COUNT(email_subscribers.id) > 0')
        .order('COUNT(email_subscribers.id) DESC')
        .limit(10)
        .map { |blog| { blog: blog, count: blog.subscriber_count } }
    end
end
