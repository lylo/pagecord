require "test_helper"

class Analytics::TrendingTest < ActiveSupport::TestCase
  setup do
    @trending = Analytics::Trending.new
  end

  test "returns empty array when no posts have engagement" do
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

  test "applies recency decay favoring newer posts" do
    recent = posts(:one)
    older = posts(:two)

    recent.update_column(:published_at, Date.current)
    older.update_column(:published_at, 30.days.ago)

    PageView.create!(blog: recent.blog, post: recent, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-recent")
    PageView.create!(blog: older.blog, post: older, viewed_at: 1.day.ago, is_unique: true, visitor_hash: "test-older")

    result = @trending.top_posts(limit: 10)
    recent_item = result.find { |r| r[:post] == recent }
    older_item = result.find { |r| r[:post] == older }

    assert recent_item[:score] > older_item[:score]
  end
end
