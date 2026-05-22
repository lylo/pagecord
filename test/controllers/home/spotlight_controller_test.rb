require "test_helper"

class Home::SpotlightControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test "should show spotlight page" do
    get spotlight_path

    assert_response :success
    assert_select "h1", "Spotlight"
  end

  test "should show recent tab" do
    get spotlight_path(tab: "recent")

    assert_response :success
    assert_select "h1", "Spotlight"
  end

  test "defaults to trending tab" do
    get spotlight_path

    assert_response :success
    assert_select "nav a.bg-slate-900", "Trending"
  end

  test "excludes blogs with search indexing disabled from recent" do
    blog = blogs(:joel)
    blog.update!(allow_search_indexing: false)

    get spotlight_path(tab: "recent")

    assert_response :success
    assert_no_match blog.subdomain, response.body
  end

  test "excludes posts from discarded users from recent" do
    user = users(:elliot)
    user.discard!

    get spotlight_path(tab: "recent")

    assert_response :success
    assert_no_match user.blog.subdomain, response.body
  end

  test "excludes posts published within the last 15 minutes from recent" do
    travel_to Time.zone.parse("2026-04-07 12:00:00") do
      post = posts(:one)
      post.update_column(:published_at, 5.minutes.ago)

      get spotlight_path(tab: "recent")

      assert_response :success
      assert_no_match post.slug, response.body
    end
  end

  test "excludes posts published within the last 15 minutes from trending" do
    travel_to Time.zone.parse("2026-04-07 12:00:00") do
      post = posts(:three)
      post.update_columns(published_at: 5.minutes.ago, upvotes_count: 25)
      PageView.create!(blog: post.blog, post: post, viewed_at: 5.minutes.ago, is_unique: true, visitor_hash: "fresh-post")

      get spotlight_path

      assert_response :success
      assert_no_match post.slug, response.body
    end
  end

  test "uses display_title for titleless posts" do
    post = posts(:one)
    post.update_columns(title: nil, text_summary: "Title from summary")

    get spotlight_path(tab: "recent")

    assert_response :success
    assert_match "Title from summary", response.body
  end
end
