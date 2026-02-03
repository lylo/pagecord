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

  test "newer posts with same engagement score higher" do
    recent = posts(:one)
    older = posts(:two)

    recent.update_column(:published_at, 20.days.ago)
    older.update_column(:published_at, 60.days.ago)

    # Give enough engagement so both posts have positive scores despite age penalty
    # With sqrt(views), need >36 views for 60-day-old post to score positive
    50.times do |i|
      PageView.create!(blog: recent.blog, post: recent, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-recent-#{i}")
      PageView.create!(blog: older.blog, post: older, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-older-#{i}")
    end

    result = @trending.top_posts(limit: 10)
    recent_item = result.find { |r| r[:post] == recent }
    older_item = result.find { |r| r[:post] == older }

    # Both have 50 views, but recent (20 days) beats older (60 days) due to age penalty
    assert_not_nil recent_item, "Recent post should be in results"
    assert_not_nil older_item, "Older post should be in results"
    assert recent_item[:score] > older_item[:score]
  end

  test "new posts get a multiplicative boost that decays over 14 days" do
    brand_new = posts(:one)
    week_old = posts(:two)

    brand_new.update_column(:published_at, Date.current)
    week_old.update_column(:published_at, 7.days.ago)

    # Give both the same engagement (10 views each)
    10.times do |i|
      PageView.create!(blog: brand_new.blog, post: brand_new, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-new-#{i}")
      PageView.create!(blog: week_old.blog, post: week_old, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-week-#{i}")
    end

    result = @trending.top_posts(limit: 10)
    new_item = result.find { |r| r[:post] == brand_new }
    week_item = result.find { |r| r[:post] == week_old }

    # Brand new gets 2x multiplier, week old gets 1.5x multiplier
    assert new_item[:score] > week_item[:score]
  end
end
