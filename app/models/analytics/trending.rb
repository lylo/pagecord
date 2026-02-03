class Analytics::Trending
  VIEW_WINDOW_DAYS = 14
  NEW_BOOST_DAYS = 14
  AGE_PENALTY_FACTOR = 0.1

  def top_posts(limit: 10)
    view_counts = PageView
      .where(viewed_at: VIEW_WINDOW_DAYS.days.ago.beginning_of_day..Time.current.end_of_day, is_unique: true)
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

    # Score = (engagement × boost) - age_penalty
    #
    # - engagement: views + (√upvotes × 10) — sqrt dampens viral outliers
    # - boost: 2× for brand new posts, decaying to 1× over 14 days
    # - age_penalty: -0.1 per day, so newer posts with equal engagement rank higher
    #
    # Zero engagement = zero score (won't appear in results).
    def score_post(post, view_counts)
      views = view_counts[post.id] || 0
      upvotes = post.upvotes_count
      days_old = (Date.current - post.published_at.to_date).to_i

      engagement = views + (Math.sqrt(upvotes) * 10)
      boost_multiplier = 1 + ([ NEW_BOOST_DAYS - days_old, 0 ].max / NEW_BOOST_DAYS.to_f)
      age_penalty = days_old * AGE_PENALTY_FACTOR

      score = (engagement * boost_multiplier) - age_penalty

      { post: post, score: score, views: views, upvotes: upvotes }
    end
end
