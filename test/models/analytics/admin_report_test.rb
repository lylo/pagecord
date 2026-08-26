require "test_helper"

class Analytics::AdminReportTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @post = posts(:one)
    @page = posts(:about)
    @date = Date.current.beginning_of_month
  end

  test "defaults to the current month" do
    report = Analytics::AdminReport.new(nil, nil)

    assert_equal "month", report.view_type
    assert_equal Date.current.beginning_of_month, report.date
  end

  test "parses a month and a year" do
    assert_equal Date.parse("2024-03-01"), Analytics::AdminReport.new("month", "2024-03").date
    assert_equal Date.parse("2024-01-01"), Analytics::AdminReport.new("year", "2024").date
  end

  test "falls back to the current period rather than raising for an unparseable date" do
    assert_equal Date.current.beginning_of_month, Analytics::AdminReport.new("month", "nonsense").date
    assert_equal Date.current.year, Analytics::AdminReport.new("year", "nonsense").date.year
  end

  test "sums page views and rollups for the same post" do
    create_page_view(@post)
    create_rollup("unique_views_by_blog_post", 4, post_id: @post.id, blog_id: @blog.id)

    assert_equal 5, count_for(report.top_posts, @post)
  end

  test "keeps pages out of top posts and posts out of top pages" do
    create_rollup("unique_views_by_blog_post", 3, post_id: @page.id, blog_id: @blog.id)
    create_rollup("unique_views_by_blog_post", 7, post_id: @post.id, blog_id: @blog.id)

    assert_nil count_for(report.top_posts, @page)
    assert_equal 7, count_for(report.top_posts, @post)

    assert_nil count_for(report.top_pages, @post)
    assert_equal 3, count_for(report.top_pages, @page)
  end

  test "sums page views and rollups for the same blog" do
    create_page_view(@post)
    create_rollup("unique_views_by_blog", 9, blog_id: @blog.id)

    top = report.top_blogs.find { |item| item[:blog] == @blog }
    assert_equal 10, top[:count]
  end

  test "ignores views outside the period" do
    create_page_view(@post, viewed_at: 2.months.ago)

    assert_nil count_for(report.top_posts, @post)
  end

  test "ranks by descending count" do
    create_rollup("unique_views_by_blog_post", 2, post_id: @post.id, blog_id: @blog.id)
    create_rollup("unique_views_by_blog_post", 8, post_id: posts(:two).id, blog_id: @blog.id)

    assert_equal [ posts(:two), @post ], report.top_posts.map { |item| item[:post] }
  end

  private

    def report
      Analytics::AdminReport.new("month", @date.strftime("%Y-%m"))
    end

    def count_for(items, post)
      items.find { |item| item[:post] == post }&.fetch(:count)
    end

    def create_page_view(post, viewed_at: @date.beginning_of_day + 1.hour)
      PageView.create!(
        blog: @blog,
        post: post,
        visitor_hash: SecureRandom.hex(4),
        user_agent: "Test Browser",
        is_unique: true,
        viewed_at: viewed_at
      )
    end

    def create_rollup(name, value, dimensions)
      Rollup.create!(
        name: name,
        time: @date.beginning_of_day + 1.hour,
        interval: "day",
        value: value,
        dimensions: dimensions
      )
    end
end
