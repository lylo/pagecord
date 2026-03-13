require "test_helper"

class Posts::Upvotes::StatusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    host! "#{@post.blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "returns upvoted false when visitor has not upvoted" do
    get post_upvotes_status_path(@post)
    assert_response :success
    assert_equal({ "upvoted" => false }, response.parsed_body)
  end

  test "returns upvoted true when visitor has upvoted" do
    post post_upvotes_path(@post), as: :turbo_stream
    get post_upvotes_status_path(@post)
    assert_response :success
    assert_equal({ "upvoted" => true }, response.parsed_body)
  end
end
