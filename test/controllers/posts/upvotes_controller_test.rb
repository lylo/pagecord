require "test_helper"

class Posts::UpvotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    host! "#{@post.blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should create upvote" do
    assert_difference("Upvote.count", 1) do
      post post_upvotes_path(@post), as: :turbo_stream
    end
    assert_response :success
  end

  test "should not create duplicate upvote" do
    post post_upvotes_path(@post), as: :turbo_stream

    assert_no_difference("Upvote.count") do
      post post_upvotes_path(@post), as: :turbo_stream
    end
    assert_response :success
  end

  test "should destroy upvote" do
    post post_upvotes_path(@post), as: :turbo_stream
    upvote = Upvote.last

    assert_difference("Upvote.count", -1) do
      delete post_upvote_path(@post, upvote), as: :turbo_stream
    end
    assert_response :success
  end

  test "should return not found for non-existent upvote" do
    delete "/posts/#{@post.to_param}/upvotes/unknown", as: :turbo_stream
    assert_response :not_found
  end
end
