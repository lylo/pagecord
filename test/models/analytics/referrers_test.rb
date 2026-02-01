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
end
