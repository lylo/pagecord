require "test_helper"

class Blogs::PostDigestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @digest = post_digests(:one)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "shows digest posts" do
    get blog_post_digest_path(@digest.masked_id)

    assert_response :success
    assert_includes @response.body, "The Art of Street Photography"
    assert_includes @response.body, "The Beauty of Landscape Photography"
  end

  test "returns not found for invalid masked id" do
    get blog_post_digest_path("unknown")

    assert_response :not_found
  end

  test "returns not found for digest from another blog" do
    host! "vivian.#{Rails.application.config.x.domain}"

    get blog_post_digest_path(@digest.masked_id)

    assert_response :not_found
  end

  test "does not show posts that are no longer public" do
    @digest.digest_posts.create!(post: posts(:joel_hidden))

    get blog_post_digest_path(@digest.masked_id)

    assert_response :success
    assert_no_match "A Hidden Thought", @response.body
  end
end
