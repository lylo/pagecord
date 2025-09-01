require "test_helper"

class Analytics::ChartTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @chart = Analytics::Chart.new(@blog)
  end

  test "month chart uses raw data when no rollups exist" do
    # Create pageviews for last month
    PageView.create!(
      blog: @blog,
      visitor_hash: "month_visitor",
      ip_address: "127.0.0.1",
      user_agent: "Test Browser",
      is_unique: true,
      viewed_at: 1.month.ago
    )

    # Should use raw data since no rollups exist
    chart_data = @chart.chart_data("month", 1.month.ago.beginning_of_month.to_date, nil)
    total_views = chart_data.sum { |day| day[:total_page_views] }
    assert_equal 1, total_views
  end

  test "month chart uses rollups when they exist and month is before cutoff" do
    # Create rollups for old month
    old_date = 3.months.ago.beginning_of_month
    Rollup.create!(
      name: "unique_views_by_blog",
      time: old_date.beginning_of_day,
      interval: "day",
      value: 2.0,
      dimensions: { blog_id: @blog.id }
    )
    Rollup.create!(
      name: "total_views_by_blog",
      time: old_date.beginning_of_day,
      interval: "day",
      value: 4.0,
      dimensions: { blog_id: @blog.id }
    )

    # Should use rollup data
    chart_data = @chart.chart_data("month", old_date.to_date, nil)
    day_data = chart_data.find { |day| day[:date] == old_date.to_date }
    assert_equal 4, day_data[:total_page_views]
    assert_equal 2, day_data[:unique_page_views]
  end

  test "year chart handles mixed rollup and raw data" do
    # Create rollups (enables cutoff logic)
    Rollup.create!(name: "test", time: 6.months.ago, interval: "day", value: 1.0, dimensions: {})

    # Create old pageview (should be ignored since rollups exist for old data)
    PageView.create!(
      blog: @blog,
      visitor_hash: "old_visitor",
      ip_address: "127.0.0.1",
      user_agent: "Test Browser",
      is_unique: true,
      viewed_at: 6.months.ago
    )

    # Create recent pageview (should be used since it's after cutoff)
    PageView.create!(
      blog: @blog,
      visitor_hash: "recent_visitor",
      ip_address: "127.0.0.1",
      user_agent: "Test Browser",
      is_unique: true,
      viewed_at: 1.week.ago
    )

    chart_data = @chart.chart_data("year", Date.current.beginning_of_year, nil)

    # Should have data for recent month from pageviews
    recent_month_data = chart_data.find { |month| month[:date].month == 1.week.ago.month }
    assert_equal 1, recent_month_data[:total_page_views]
  end
end
