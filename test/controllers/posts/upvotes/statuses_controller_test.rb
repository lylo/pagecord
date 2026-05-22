require "test_helper"

class Posts::Upvotes::StatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @post_one = posts(:one)
    @post_two = posts(:two)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "returns statuses for multiple posts" do
    post post_upvotes_path(@post_one), as: :turbo_stream

    get upvotes_statuses_path(tokens: [ @post_one.token, @post_two.token ])
    assert_response :success

    body = response.parsed_body
    assert_equal true, body[@post_one.token]
    assert_equal false, body[@post_two.token]
  end

  test "returns empty hash for unknown tokens" do
    get upvotes_statuses_path(tokens: [ "nonexistent" ])
    assert_response :success
    assert_equal({}, response.parsed_body)
  end
end
