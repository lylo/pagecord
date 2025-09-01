require "test_helper"

class Analytics::SummaryTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @summary = Analytics::Summary.new(@blog)
  end

  test "uses raw pageviews when no rollups exist" do
    # Create some pageviews
    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor1",
      ip_address: "127.0.0.1",
      user_agent: "Test Browser",
      is_unique: true,
      viewed_at: 2.months.ago
    )

    # Should use raw data since no rollups exist
    data = @summary.analytics_data("month", 2.months.ago.beginning_of_month.to_date)
    assert_equal 1, data[:total_page_views]
    assert_equal 1, data[:unique_page_views]
  end

  test "uses rollups when they exist and date is before cutoff" do
    # Create rollup data for 3 months ago
    cutoff_time = Date.current.prev_month.beginning_of_month.beginning_of_day
    old_time = 3.months.ago.beginning_of_month.beginning_of_day

    Rollup.create!(
      name: "unique_views_by_blog",
      time: old_time,
      interval: "day",
      value: 5.0,
      dimensions: { blog_id: @blog.id }
    )
    Rollup.create!(
      name: "total_views_by_blog",
      time: old_time,
      interval: "day",
      value: 10.0,
      dimensions: { blog_id: @blog.id }
    )

    # Should use rollup data
    data = @summary.analytics_data("month", 3.months.ago.beginning_of_month.to_date)
    assert_equal 10, data[:total_page_views]
    assert_equal 5, data[:unique_page_views]
  end

  test "uses raw pageviews for current month even when rollups exist" do
    # Create rollups (so cutoff_time works)
    Rollup.create!(name: "test", time: 3.months.ago, interval: "day", value: 1.0, dimensions: {})

    # Create current month pageview
    PageView.create!(
      blog: @blog,
      visitor_hash: "current_visitor",
      ip_address: "127.0.0.1",
      user_agent: "Test Browser",
      is_unique: true,
      viewed_at: Time.current
    )

    # Should use raw data for current month
    data = @summary.analytics_data("month", Date.current.beginning_of_month)
    assert_equal 1, data[:total_page_views]
    assert_equal 1, data[:unique_page_views]
  end
end
