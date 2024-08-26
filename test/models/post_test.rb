require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "should be valid with body" do
    @post = Post.new(user: users(:joel), content: "Test post")
    assert @post.valid?
  end

  test "should not be valid without body or title" do
    @post = Post.new(user: users(:joel), content: nil, title: nil)
    assert_not @post.valid?
  end

  test "published at should be set on create if not provided" do
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post"

    assert_equal post.created_at, post.published_at
  end

  test "published at should be set" do
    published_at = 1.day.ago
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post", published_at: published_at

    assert_equal published_at.to_time.to_i, post.published_at.to_time.to_i
  end

  test "post with blank title and body should be invalid" do
    assert_not users(:joel).posts.build(title: "", content: "").valid?
  end
end
