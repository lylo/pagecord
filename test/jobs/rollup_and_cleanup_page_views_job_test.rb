require "test_helper"

class RollupAndCleanupPageViewsJobTest < ActiveJob::TestCase
  setup do
    @blog = blogs(:joel)
    @post = posts(:one)
    @job  = RollupAndCleanupPageViewsJob.new
  end

  def create_page_view(attrs = {})
    PageView.create!(
      {
        blog: @blog,
        post: @post,
        visitor_hash: SecureRandom.hex(8),
        user_agent: "Minitest Browser",
        is_unique: false,
        viewed_at: Time.current
      }.merge(attrs)
    )
  end

  test "performs rollups and deletes old page views when rollups exist" do
    # Create some rollup data first so cutoff_time works properly
    Rollup.create!(name: "test", time: 3.months.ago, interval: "day", value: 1.0, dimensions: {})

    # Old data that should be rolled up and deleted (2+ months ago)
    old_date = 3.months.ago
    3.times { |i| create_page_view(visitor_hash: "unique#{i}", is_unique: true, viewed_at: old_date + i.hours) }
    2.times { |i| create_page_view(visitor_hash: "repeat_hash", is_unique: false, viewed_at: old_date + (i + 3).hours) }

    # Recent data that should survive (current and previous month)
    recent1 = create_page_view(visitor_hash: "recent1", is_unique: true, viewed_at: 1.month.ago)
    recent2 = create_page_view(visitor_hash: "recent2", is_unique: true, viewed_at: 1.day.ago)

    assert_equal 7, PageView.count

    deleted_count = @job.perform

    # Verify deletion
    assert_equal 5, deleted_count, "Expected 5 old views to be deleted"
    assert_equal [ recent1.id, recent2.id ].sort, PageView.pluck(:id).sort, "Recent views should remain"

    # Verify rollups (only unique views now)
    unique_rollups = Rollup.where(name: "unique_views")

    assert unique_rollups.exists?, "Expected unique_views rollups to exist"
    assert_equal 3.0, unique_rollups.sum(:value)
    assert_equal "day", unique_rollups.first.interval

    # No total_views rollups should be created
    assert_not Rollup.where(name: "total_views").exists?
  end

  test "handles case when no rollups exist" do
    # Job always uses fixed cutoff date regardless of existing rollups
    old_view = create_page_view(visitor_hash: "old", is_unique: true, viewed_at: 3.months.ago)
    recent_view = create_page_view(visitor_hash: "recent", is_unique: true, viewed_at: 1.day.ago)

    assert_equal 2, PageView.count
    assert_equal 0, Rollup.count

    deleted_count = @job.perform

    assert_equal 1, deleted_count, "Old view should be deleted even when no rollups exist"
    assert_equal [ recent_view.id ], PageView.pluck(:id), "Recent view should remain"
    # 5 rollup types: unique_views, unique_views_by_blog, unique_views_by_blog_post,
    # unique_views_by_blog_referrer, unique_views_by_blog_country
    assert_equal 5, Rollup.count, "New rollups should be created (unique views only)"
  end

  test "handles empty dataset gracefully" do
    assert_equal 0, PageView.count

    deleted_count = @job.perform

    assert_equal 0, deleted_count
    assert_equal 0, PageView.count
    assert_equal 0, Rollup.count
  end

  test "creates rollups with correct referrer_domain dimensions" do
    old_date = 3.months.ago

    create_page_view(visitor_hash: "v1", referrer_domain: "google.com", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v2", referrer_domain: "google.com", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v3", referrer_domain: "x.com", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v4", referrer_domain: nil, is_unique: true, viewed_at: old_date)

    @job.perform

    referrer_rollups = Rollup.where(name: "unique_views_by_blog_referrer")
    assert referrer_rollups.exists?, "Expected referrer rollups to exist"

    google_rollup = referrer_rollups.find_by("dimensions->>'referrer_domain' = ?", "google.com")
    assert_not_nil google_rollup, "Expected google.com rollup"
    assert_equal 2.0, google_rollup.value
    assert_equal @blog.id, google_rollup.dimensions["blog_id"]

    x_rollup = referrer_rollups.find_by("dimensions->>'referrer_domain' = ?", "x.com")
    assert_not_nil x_rollup, "Expected x.com rollup"
    assert_equal 1.0, x_rollup.value

    # Direct traffic (nil referrer) should also be rolled up
    direct_rollup = referrer_rollups.where("dimensions->>'referrer_domain' IS NULL").first
    assert_not_nil direct_rollup, "Expected direct traffic rollup"
    assert_equal 1.0, direct_rollup.value
  end

  test "creates rollups with correct country dimensions" do
    old_date = 3.months.ago

    create_page_view(visitor_hash: "v1", country: "US", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v2", country: "US", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v3", country: "GB", is_unique: true, viewed_at: old_date)
    create_page_view(visitor_hash: "v4", country: nil, is_unique: true, viewed_at: old_date)

    @job.perform

    country_rollups = Rollup.where(name: "unique_views_by_blog_country")
    assert country_rollups.exists?, "Expected country rollups to exist"

    us_rollup = country_rollups.find_by("dimensions->>'country' = ?", "US")
    assert_not_nil us_rollup, "Expected US rollup"
    assert_equal 2.0, us_rollup.value
    assert_equal @blog.id, us_rollup.dimensions["blog_id"]

    gb_rollup = country_rollups.find_by("dimensions->>'country' = ?", "GB")
    assert_not_nil gb_rollup, "Expected GB rollup"
    assert_equal 1.0, gb_rollup.value

    # Nil country should also be rolled up
    nil_country_rollup = country_rollups.where("dimensions->>'country' IS NULL").first
    assert_not_nil nil_country_rollup, "Expected nil country rollup"
    assert_equal 1.0, nil_country_rollup.value
  end
end
