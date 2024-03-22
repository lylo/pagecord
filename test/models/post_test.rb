require "test_helper"

class PostTest < ActiveSupport::TestCase

  test "published at should be set on create if not provided" do
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post", html: false

    assert_equal post.created_at, post.published_at
  end

  test "published at should be set" do
    published_at = 1.day.ago.to_time
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post", html: false, published_at: published_at

    assert_equal published_at, post.published_at
  end
end
