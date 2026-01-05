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

  test "should exclude blogs with search indexing disabled" do
    blog = blogs(:joel)
    blog.update!(allow_search_indexing: false)

    get shuffle_path
    refute_match /#{blog.subdomain}\./, response.location
  end

  test "should exclude posts from discarded users" do
    user = users(:joel)
    user.discard!

    get shuffle_path
    refute_match /#{user.blog.subdomain}\./, response.location
  end

  test "should redirect to root when no eligible posts exist" do
    Post.update_all(hidden: true)

    get shuffle_path

    assert_redirected_to root_path
    assert_equal "No posts available right now", flash[:alert]
  end
end
