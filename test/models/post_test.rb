require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "should generate a token on create" do
    post = Post.create(blog: blogs(:joel), title: "a new post")
    assert post.token.present?
  end

  test "should be valid with body" do
    @post = Post.new(blog: blogs(:joel), content: "Test post")
    assert @post.valid?
  end

  test "should not be valid without body or title" do
    @post = Post.new(blog: blogs(:joel), content: nil, title: nil)
    assert_not @post.valid?
  end

  test "published at should be set on create if not provided" do
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post"

    assert_equal post.created_at, post.published_at
  end

  test "published at should be set" do
    published_at = 1.day.ago
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post", published_at: published_at

    assert_equal published_at.to_time.to_i, post.published_at.to_time.to_i
  end

  test "should exclude future-dated posts from published" do
    post = Post.create(blog: blogs(:joel), title: "a new post", published_at: 1.day.from_now)
    assert_not Post.published.include?(post)
  end

  test "post with blank title and body should be invalid" do
    assert_not blogs(:joel).posts.build(title: "", content: "").valid?
  end

  test "destroying a post should destroy digest posts" do
    assert_difference "DigestPost.count", -1 do
      posts(:one).destroy
    end
  end
end
