require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "should be valid with content" do
    @post = Post.new(user: users(:joel), content: "Test post", html: false)
    assert @post.valid?
  end

  test "should not be valid without content or title" do
    @post = Post.new(user: users(:joel), content: nil, title: nil, html: false)
    assert_not @post.valid?
  end

  test "should limit content size" do
    @post = Post.new(user: users(:joel), html: false)
    @post.content = "a" * 65.kilobytes
    @post.save
    assert_equal "a" * 64.kilobytes, @post.reload.content
  end

  test "published at should be set on create if not provided" do
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post", html: false

    assert_equal post.created_at, post.published_at
  end

  test "published at should be set" do
    published_at = 1.day.ago
    post = users(:joel).posts.create! title: "my new post", content: "this is my new post", html: false, published_at: published_at

    assert_equal published_at.to_time.to_i, post.published_at.to_time.to_i
  end

  test "post with blank title and content should be invalid" do
    refute users(:joel).posts.build(title: "", content: "", html: false).valid?
  end

  test "should enqueue GenerateOpenGraphImageJob after create" do
    @post = Post.create!(user: users(:joel), content: "Test post <img src=\"test.jpg\|>", html: true)

    assert @post.open_graph_image.present?
  end
end
