require "test_helper"

class Analytics::ReferrersTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @referrers = Analytics::Referrers.new(@blog)
  end

  test "returns referrer data from page views" do
    # Create page views with different referrer domains
    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor1",
      user_agent: "Test Browser",
      referrer: "https://google.com/search",
      referrer_domain: "google.com",
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor2",
      user_agent: "Test Browser",
      referrer: "https://google.com/search?q=test",
      referrer_domain: "google.com",
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor3",
      user_agent: "Test Browser",
      referrer: "https://twitter.com/user",
      referrer_domain: "x.com",  # Normalized from twitter.com
      is_unique: true,
      viewed_at: Time.current
    )

    data = @referrers.referrer_data("day", Date.current)

    assert_equal 2, data.length

    # Google should be first (2 views)
    google = data.find { |r| r[:domain] == "google.com" }
    assert_equal 2, google[:count]
    assert_equal "Google", google[:friendly_name]
    assert_equal "icons/search.svg", google[:icon_path]

    # X should be second (1 view) - twitter.com is normalized to x.com
    x = data.find { |r| r[:domain] == "x.com" }
    assert_equal 1, x[:count]
    assert_equal "X", x[:friendly_name]
  end

  test "includes direct traffic with nil domain" do
    PageView.create!(
      blog: @blog,
      visitor_hash: "visitor1",
      user_agent: "Test Browser",
      referrer: nil,
      referrer_domain: nil,
      is_unique: true,
      viewed_at: Time.current
    )

    data = @referrers.referrer_data("day", Date.current)

    assert_equal 1, data.length
    direct = data.first
    assert_nil direct[:domain]
    assert_equal "Direct", direct[:friendly_name]
    assert direct[:direct]
  end

  test "limits results to specified count" do
    # Create 15 different referrers
    15.times do |i|
      PageView.create!(
        blog: @blog,
        visitor_hash: "visitor#{i}",
        user_agent: "Test Browser",
        referrer: "https://site#{i}.com",
        referrer_domain: "site#{i}.com",
        is_unique: true,
        viewed_at: Time.current
      )
    end

    data = @referrers.referrer_data("day", Date.current, limit: 5)
    assert_equal 5, data.length
  end

  test "orders by count descending" do
    3.times do |i|
      PageView.create!(
        blog: @blog,
        visitor_hash: "google_visitor#{i}",
        user_agent: "Test Browser",
        referrer_domain: "google.com",
        is_unique: true,
        viewed_at: Time.current
      )
    end

    PageView.create!(
      blog: @blog,
      visitor_hash: "x_visitor",
      user_agent: "Test Browser",
      referrer_domain: "x.com",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @referrers.referrer_data("day", Date.current)

    assert_equal "google.com", data.first[:domain]
    assert_equal 3, data.first[:count]
    assert_equal "x.com", data.second[:domain]
    assert_equal 1, data.second[:count]
  end

  test "returns referrer data from rollups when data is old" do
    # Create rollups for 3 months ago
    old_date = 3.months.ago.beginning_of_month

    Rollup.create!(
      name: "unique_views_by_blog_referrer",
      time: old_date,
      interval: "day",
      value: 5.0,
      dimensions: { "blog_id" => @blog.id.to_s, "referrer_domain" => "google.com" }
    )

    Rollup.create!(
      name: "unique_views_by_blog_referrer",
      time: old_date,
      interval: "day",
      value: 2.0,
      dimensions: { "blog_id" => @blog.id.to_s, "referrer_domain" => "x.com" }
    )

    # Query for that old month - should use rollups
    data = @referrers.referrer_data("month", old_date.to_date)

    assert_equal 2, data.length

    google = data.find { |r| r[:domain] == "google.com" }
    assert_equal 5, google[:count]
    assert_equal "Google", google[:friendly_name]

    x = data.find { |r| r[:domain] == "x.com" }
    assert_equal 2, x[:count]
  end

  test "returns direct traffic from rollups with nil domain" do
    old_date = 3.months.ago.beginning_of_month

    Rollup.create!(
      name: "unique_views_by_blog_referrer",
      time: old_date,
      interval: "day",
      value: 10.0,
      dimensions: { "blog_id" => @blog.id.to_s, "referrer_domain" => nil }
    )

    data = @referrers.referrer_data("month", old_date.to_date)

    assert_equal 1, data.length
    assert_nil data.first[:domain]
    assert_equal "Direct", data.first[:friendly_name]
    assert_equal 10, data.first[:count]
  end

  test "excludes self-referrals from blog's own domains" do
    # Self-referral from subdomain (joel.example.com in test env)
    PageView.create!(
      blog: @blog,
      visitor_hash: "self_visitor1",
      user_agent: "Test Browser",
      referrer: "https://joel.example.com/some-post",
      referrer_domain: "joel.example.com",
      is_unique: true,
      viewed_at: Time.current
    )

    # External referral
    PageView.create!(
      blog: @blog,
      visitor_hash: "external_visitor",
      user_agent: "Test Browser",
      referrer: "https://google.com/search",
      referrer_domain: "google.com",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @referrers.referrer_data("day", Date.current)

    # Should only include external referrer, not self-referral
    assert_equal 1, data.length
    assert_equal "google.com", data.first[:domain]
  end

  test "excludes self-referrals from custom domain" do
    @blog.update!(custom_domain: "myblog.com")

    PageView.create!(
      blog: @blog,
      visitor_hash: "self_visitor",
      user_agent: "Test Browser",
      referrer_domain: "myblog.com",
      is_unique: true,
      viewed_at: Time.current
    )

    PageView.create!(
      blog: @blog,
      visitor_hash: "external_visitor",
      user_agent: "Test Browser",
      referrer_domain: "x.com",
      is_unique: true,
      viewed_at: Time.current
    )

    data = @referrers.referrer_data("day", Date.current)

    assert_equal 1, data.length
    assert_equal "x.com", data.first[:domain]
  end

  test "combines rollup and pageview data for mixed time ranges" do
    # Create a rollup at the beginning of the year (will be in rollup range)
    # cutoff_time is prev_month.beginning_of_month, so Jan 1 data is before cutoff if we're in Feb+
    year_start = Date.current.beginning_of_year

    Rollup.create!(
      name: "unique_views_by_blog_referrer",
      time: year_start.to_time,
      interval: "day",
      value: 10.0,
      dimensions: { "blog_id" => @blog.id.to_s, "referrer_domain" => "google.com" }
    )

    # Create pageview for current month (will be in pageview range)
    PageView.create!(
      blog: @blog,
      visitor_hash: "recent_visitor",
      user_agent: "Test Browser",
      referrer_domain: "google.com",
      is_unique: true,
      viewed_at: Time.current
    )

    # Query for the full year - should combine both sources
    data = @referrers.referrer_data("year", Date.current)

    google = data.find { |r| r[:domain] == "google.com" }
    assert_not_nil google, "Expected google.com in results"
    assert_equal 11, google[:count], "Expected combined count from rollup (10) + pageview (1)"
  end
end
