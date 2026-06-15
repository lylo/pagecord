require "test_helper"

class Blog::SpotlitTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "blogs are spotlit by default" do
    assert @blog.spotlit?
    assert_includes Blog.spotlit, @blog
  end

  test "excludes blogs with search indexing disabled" do
    @blog.update!(allow_search_indexing: false)

    assert_not @blog.spotlit?
    assert_not_includes Blog.spotlit, @blog
  end

  test "excludes blogs whose user is discarded" do
    @blog.user.discard!

    assert_not @blog.reload.spotlit?
    assert_not_includes Blog.spotlit, @blog
  end

  test "excludes blogs whose user was recently created" do
    travel_to Time.zone.parse("2026-04-07 12:00:00") do
      @blog.user.update!(created_at: 6.days.ago)

      assert_not @blog.reload.spotlit?
      assert_not_includes Blog.spotlit, @blog
    end
  end

  test "excludes blogs with a spotlight_exclusion" do
    @blog.exclude_from_spotlight

    assert_not @blog.spotlit?
    assert_not_includes Blog.spotlit, @blog
  end

  test "exclude_from_spotlight is idempotent" do
    @blog.exclude_from_spotlight
    @blog.exclude_from_spotlight

    assert_equal 1, Blog::SpotlightExclusion.where(blog: @blog).count
  end

  test "include_in_spotlight removes the exclusion" do
    @blog.exclude_from_spotlight
    assert_not @blog.spotlit?

    @blog.include_in_spotlight

    assert @blog.reload.spotlit?
    assert_nil @blog.spotlight_exclusion
  end

  test "include_in_spotlight is a no-op when not excluded" do
    assert_nothing_raised { @blog.include_in_spotlight }
  end
end
