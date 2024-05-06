require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "post_title with title present" do
    post = posts(:one)
    assert_equal post.title, post_title(post)

    post.title = "A" * 120
    assert_equal "#{'A' * 97}...", post_title(post)
  end

  test "post_title without title present" do
    post = User.first.posts.build body: "Test post", html: false
    assert_equal "Test post", post_title(post)

    post = User.first.posts.build body: "<p></p>", html: true
    assert_equal "Untitled", post_title(post)

    post = User.first.posts.build body: "<div><p>Hello, World</p><img src='example.com'></div>", html: true
    assert_equal "Hello, World", post_title(post)
  end

  test "user_title with no title" do
    user = User.first
    assert_equal "Posts from @#{user.username}", user_title(user)
  end

  test "user_title with title" do
    user = User.build title: "My blog"
    assert_equal "My blog", user_title(user)
  end

  test "blog_description with no bio" do
    user = User.build title: "My blog"
    assert_equal "My blog", blog_description(user)
  end

  test "blog_description with bio" do
    user = users(:joel)
    bio = <<~BIO
    American street, portrait and landscape photographer. Photographing in color since 1962.

    https://joelmeyerowitz.com
    joel@joelmeyerowitz....
    BIO

    assert_equal bio.strip, blog_description(user)
  end
end