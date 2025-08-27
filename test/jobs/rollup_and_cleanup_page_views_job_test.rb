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
        ip_address: "127.0.0.1",
        user_agent: "Minitest Browser",
        is_unique: false,
        viewed_at: Time.current
      }.merge(attrs)
    )
  end

  test "performs rollups and deletes old page views" do
    old_date = 35.days.ago

    # 3 unique old views
    3.times { |i| create_page_view(visitor_hash: "unique#{i}", is_unique: true, viewed_at: old_date + i.hours) }

    # 2 non-unique old views
    2.times { |i| create_page_view(visitor_hash: "repeat_hash", is_unique: false, viewed_at: old_date + (i + 3).hours) }

    # 1 recent view (should survive)
    recent = create_page_view(visitor_hash: "recent", is_unique: true, viewed_at: 1.day.ago)

    assert_equal 6, PageView.count

    deleted_count = @job.perform

    # Verify deletion
    assert_equal 5, deleted_count, "Expected 5 old views to be deleted"
    assert_equal [ recent.id ], PageView.pluck(:id), "Only recent view should remain"

    # Verify rollups
    total_rollup  = Rollup.find_by(name: "total_views")
    unique_rollup = Rollup.find_by(name: "unique_views")

    assert total_rollup, "Expected total_views rollup to exist"
    assert_equal 5.0, total_rollup.value
    assert_equal "day", total_rollup.interval
    assert_in_delta old_date.to_date, total_rollup.time.to_date, 1, "Rollup time should match old view date"

    assert unique_rollup, "Expected unique_views rollup to exist"
    assert_equal 3.0, unique_rollup.value
    assert_equal "day", unique_rollup.interval
    assert_in_delta old_date.to_date, unique_rollup.time.to_date, 1, "Rollup time should match old unique view date"
  end

  test "handles empty dataset gracefully" do
    assert_equal 0, PageView.count

    deleted_count = @job.perform

    assert_equal 0, deleted_count
    assert_equal 0, PageView.count
    assert_equal 0, Rollup.count
  end
end

