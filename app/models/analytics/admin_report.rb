class Analytics::AdminReport
  LIMIT = 10

  attr_reader :view_type, :date

  def initialize(view_type, date_param)
    @view_type = view_type.presence || "month"
    @date = parse_date(date_param)
  end

  def top_posts
    posts_by_views(is_page: false)
  end

  def top_pages
    posts_by_views(is_page: true)
  end

  def top_blogs
    counts = merge_rollups(
      PageView.joins(:blog).where(is_unique: true, viewed_at: period).group("blogs.id").count,
      "unique_views_by_blog",
      "blog_id"
    )

    blogs_for(counts)
  end

  def top_blogs_by_subscribers
    Blog.joins(:email_subscribers)
      .group(:id)
      .select("blogs.*, COUNT(email_subscribers.id) as subscriber_count")
      .having("COUNT(email_subscribers.id) > 0")
      .order("COUNT(email_subscribers.id) DESC")
      .limit(LIMIT)
      .map { |blog| { blog: blog, count: blog.subscriber_count } }
  end

  def top_posts_by_comments
    counts = Post::Comment.approved
      .where(author: false, created_at: period)
      .group(:post_id)
      .order(count_all: :desc)
      .limit(LIMIT)
      .count

    posts_for(counts)
  end

  def trending_posts
    Analytics::Trending.new.top_posts(limit: LIMIT)
  end

  private

    def parse_date(date_param)
      parse_param(date_param) || default_date
    rescue ArgumentError
      default_date
    end

    def parse_param(date_param)
      return if date_param.blank?

      case view_type
      when "month" then Date.parse("#{date_param}-01")
      when "year"  then Date.parse("#{date_param}-01-01")
      end
    end

    def default_date
      case view_type
      when "month" then Date.current.beginning_of_month
      when "year"  then Date.current.beginning_of_year
      end
    end

    def period
      @period ||= case view_type
      when "month" then date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
      when "year"  then date.beginning_of_year.beginning_of_day..date.end_of_year.end_of_day
      end
    end

    def posts_by_views(is_page:)
      counts = merge_rollups(
        PageView.joins(:post)
          .where(posts: { is_page: is_page }, is_unique: true, viewed_at: period)
          .group("posts.id").count,
        "unique_views_by_blog_post",
        "post_id"
      ) { |post_ids| Post.where(id: post_ids, is_page: is_page).pluck(:id) }

      posts_for(counts)
    end

    # Views are split between live PageView rows and Rollup rows once a period
    # has been rolled up, so both sides are summed per id before ranking.
    def merge_rollups(page_view_counts, rollup_name, dimension)
      totals = page_view_counts.dup

      rollups = Rollup.where(name: rollup_name, interval: "day", time: period)
        .group("dimensions->>'#{dimension}'")
        .sum(:value)
        .transform_keys { |id| id&.to_i }
        .except(nil)

      rollups = rollups.slice(*yield(rollups.keys)) if block_given?
      rollups.each { |id, count| totals[id] = totals.fetch(id, 0) + count.to_i }

      totals
    end

    def top_ids(counts)
      counts.sort_by { |_, count| -count }.first(LIMIT).map(&:first)
    end

    def posts_for(counts)
      Post.includes(:blog)
        .where(id: top_ids(counts))
        .map { |post| { post: post, count: counts.fetch(post.id, 0) } }
        .sort_by { |item| -item[:count] }
    end

    def blogs_for(counts)
      Blog.where(id: top_ids(counts))
        .map { |blog| { blog: blog, count: counts.fetch(blog.id, 0) } }
        .sort_by { |item| -item[:count] }
    end
end
