class Analytics::Trending
  WINDOW_DAYS = 14
  VIEW_WEIGHT = 1.0
  UPVOTE_WEIGHT = 10.0
  DECAY_RATE = 0.05

  def top_posts(limit: 10)
    view_counts = PageView
      .where(viewed_at: WINDOW_DAYS.days.ago.beginning_of_day..Time.current.end_of_day, is_unique: true)
      .where.not(post_id: nil)
      .group(:post_id)
      .count

    Post.visible.posts
      .where("published_at > ?", 90.days.ago)
      .includes(:blog)
      .map { |post| score_post(post, view_counts) }
      .select { |item| item[:score] > 0 }
      .sort_by { |item| -item[:score] }
      .first(limit)
  end

  private

    def score_post(post, view_counts)
      views = view_counts[post.id] || 0
      upvotes = post.upvotes_count
      days_old = (Date.current - post.published_at.to_date).to_i
      multiplier = Math.exp(-DECAY_RATE * days_old)
      score = ((views * VIEW_WEIGHT) + (upvotes * UPVOTE_WEIGHT)) * multiplier

      { post: post, score: score, views: views, upvotes: upvotes }
    end
end
