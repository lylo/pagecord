require "test_helper"

class Analytics::CountriesTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @countries = Analytics::Countries.new(@blog)
  end

  test "returns country data from page views" do
    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor1",
      user_agent: "Test Browser",
      country: "US",
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor2",
      user_agent: "Test Browser",
      country: "US",
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor3",
      user_agent: "Test Browser",
      country: "GB",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @countries.country_data("day", Date.current)

    assert_equal 2, data.length

    # US should be first (2 views)
    us = data.find { |c| c[:code] == "US" }
    assert_equal 2, us[:count]
    assert_equal "United States", us[:name]
    assert_equal "\u{1F1FA}\u{1F1F8}", us[:flag]

    # UK should be second (1 view)
    gb = data.find { |c| c[:code] == "GB" }
    assert_equal 1, gb[:count]
    assert_equal "United Kingdom", gb[:name]
  end

  test "excludes page views with nil country" do
    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor1",
      user_agent: "Test Browser",
      country: nil,
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor2",
      user_agent: "Test Browser",
      country: "US",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @countries.country_data("day", Date.current)

    assert_equal 1, data.length
    assert_equal "US", data.first[:code]
  end

  test "limits results to specified count" do
    country_codes = %w[US GB DE FR CA AU JP IN BR NL SE CH PL BE AT]

    country_codes.each_with_index do |code, i|
      PageView.create!(
        blog: @blog,
        visitor_hash: "visitor#{i}",
        user_agent: "Test Browser",
        country: code,
        is_unique: true,
        viewed_at: Time.current
      )
    end

    data = @countries.country_data("day", Date.current, limit: 5)
    assert_equal 5, data.length
  end

  test "orders by count descending" do
    3.times do |i|
      PageView.create!(
        blog: @blog,
        visitor_hash: "us_visitor#{i}",
        user_agent: "Test Browser",
        country: "US",
        is_unique: true,
        viewed_at: Time.current
      )
    end

    PageView.create!(
      blog: @blog,
      visitor_hash: "gb_visitor",
      user_agent: "Test Browser",
      country: "GB",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @countries.country_data("day", Date.current)

    assert_equal "US", data.first[:code]
    assert_equal 3, data.first[:count]
    assert_equal "GB", data.second[:code]
    assert_equal 1, data.second[:count]
  end

  test "returns country data from rollups when data is old" do
    # Create rollups for 3 months ago
    old_date = 3.months.ago.beginning_of_month

    Rollup.create!(
      name: "unique_views_by_blog_country",
      time: old_date,
      interval: "day",
      value: 15.0,
      dimensions: { "blog_id" => @blog.id.to_s, "country" => "US" }
    )

    Rollup.create!(
      name: "unique_views_by_blog_country",
      time: old_date,
      interval: "day",
      value: 8.0,
      dimensions: { "blog_id" => @blog.id.to_s, "country" => "GB" }
    )

    # Query for that old month - should use rollups
    data = @countries.country_data("month", old_date.to_date)

    assert_equal 2, data.length

    us = data.find { |c| c[:code] == "US" }
    assert_equal 15, us[:count]
    assert_equal "United States", us[:name]

    gb = data.find { |c| c[:code] == "GB" }
    assert_equal 8, gb[:count]
    assert_equal "United Kingdom", gb[:name]
  end

  test "excludes nil country from rollups" do
    old_date = 3.months.ago.beginning_of_month

    Rollup.create!(
      name: "unique_views_by_blog_country",
      time: old_date,
      interval: "day",
      value: 5.0,
      dimensions: { "blog_id" => @blog.id.to_s, "country" => "US" }
    )

    Rollup.create!(
      name: "unique_views_by_blog_country",
      time: old_date,
      interval: "day",
      value: 10.0,
      dimensions: { "blog_id" => @blog.id.to_s, "country" => nil }
    )

    data = @countries.country_data("month", old_date.to_date)

    assert_equal 1, data.length
    assert_equal "US", data.first[:code]
  end

  test "combines rollup and pageview data for mixed time ranges" do
    # Create a rollup at the beginning of the year (will be in rollup range)
    # cutoff_time is prev_month.beginning_of_month, so Jan 1 data is before cutoff if we're in Feb+
    year_start = Date.current.beginning_of_year

    Rollup.create!(
      name: "unique_views_by_blog_country",
      time: year_start.to_time,
      interval: "day",
      value: 20.0,
      dimensions: { "blog_id" => @blog.id.to_s, "country" => "US" }
    )

    # Create pageview for current month (will be in pageview range)
    PageView.create!(
      blog: @blog,
      visitor_hash: "recent_visitor",
      user_agent: "Test Browser",
      country: "US",
      is_unique: true,
      viewed_at: Time.current
    )

    # Query for the full year - should combine both sources
    data = @countries.country_data("year", Date.current)

    us = data.find { |c| c[:code] == "US" }
    assert_not_nil us, "Expected US in results"
    assert_equal 21, us[:count], "Expected combined count from rollup (20) + pageview (1)"
  end
end
