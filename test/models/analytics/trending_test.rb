require "test_helper"

class Analytics::TrendingTest < ActiveSupport::TestCase
  setup do
    @trending = Analytics::Trending.new
  end

  test "posts with no engagement do not appear" do
    # Boost is multiplicative, so zero engagement = zero score
    Post.update_all(published_at: Date.current, upvotes_count: 0)
    PageView.delete_all

    assert_equal [], @trending.top_posts(limit: 10)
  end

  test "includes posts with pageviews" do
    post = posts(:one)
    PageView.create!(blog: post.blog, post: post, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-1")

    result = @trending.top_posts(limit: 10)

    assert result.any? { |r| r[:post] == post && r[:views] == 1 }
  end

  test "includes posts with upvotes" do
    post = posts(:one)
    post.update_column(:upvotes_count, 5)

    result = @trending.top_posts(limit: 10)

    assert result.any? { |r| r[:post] == post && r[:upvotes] == 5 }
  end

  test "excludes pages" do
    page = posts(:about)
    PageView.create!(blog: page.blog, post: page, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-page")

    result = @trending.top_posts(limit: 10)

    refute result.any? { |r| r[:post] == page }
  end

  test "excludes draft posts" do
    draft = posts(:joel_draft)
    PageView.create!(blog: draft.blog, post: draft, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-draft")

    result = @trending.top_posts(limit: 10)

    refute result.any? { |r| r[:post] == draft }
  end

  test "newer posts with same engagement score higher due to age penalty" do
    recent = posts(:one)
    older = posts(:two)

    recent.update_column(:published_at, 20.days.ago)
    older.update_column(:published_at, 30.days.ago)

    view_counts = { recent.id => 100, older.id => 100 }

    recent_score = @trending.send(:score_post, recent, view_counts)[:score]
    older_score = @trending.send(:score_post, older, view_counts)[:score]

    assert recent_score > older_score
  end

  test "new posts get a multiplicative boost that decays over 14 days" do
    brand_new = posts(:one)
    week_old = posts(:two)

    brand_new.update_column(:published_at, Date.current)
    week_old.update_column(:published_at, 7.days.ago)

    view_counts = { brand_new.id => 100, week_old.id => 100 }

    new_score = @trending.send(:score_post, brand_new, view_counts)[:score]
    week_score = @trending.send(:score_post, week_old, view_counts)[:score]

    # Brand new gets 2x multiplier, week old gets 1.5x multiplier
    assert new_score > week_score
  end
end
