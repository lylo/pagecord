require "test_helper"

class Posts::UpvotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
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

  private

    def post_upvotes_path(post)
      "/posts/#{post.to_param}/upvotes"
    end

    def post_upvote_path(post, upvote)
      "/posts/#{post.to_param}/upvotes/#{upvote.id}"
    end
end
