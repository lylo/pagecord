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
end
