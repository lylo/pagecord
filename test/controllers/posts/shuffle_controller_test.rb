require "test_helper"

class Posts::ShuffleControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.application.config.x.domain
  end

  test "should redirect to a random post" do
    get shuffle_path

    assert_response :redirect
    assert_match %r{https?://\w+\.}, response.location
  end

  test "should exclude pages from shuffle" do
    page = posts(:about)
    assert page.is_page?

    get shuffle_path
    refute_match %r{/#{page.slug}$}, response.location
  end

  test "should exclude blogs that aren't spotlit" do
    blog = blogs(:joel)
    blog.exclude_from_spotlight

    get shuffle_path
    refute_match /#{blog.subdomain}\./, response.location
  end

  test "should exclude posts published within the last 2 hours" do
    travel_to Time.zone.parse("2026-04-07 12:00:00") do
      post = posts(:one)
      post.update_column(:published_at, 30.minutes.ago)

      get shuffle_path

      refute_match %r{/#{post.slug}$}, response.location
    end
  end

  test "should redirect to root when no eligible posts exist" do
    Post.update_all(hidden: true)

    get shuffle_path

    assert_redirected_to root_path
    assert_equal "No posts available right now", flash[:alert]
  end
end
