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
    post = Blog.first.posts.build content: "Test post"
    assert_equal "Test post", post_title(post)

    post = Blog.first.posts.build content: "<p></p>"
    assert_equal "Untitled", post_title(post)

    post = Blog.first.posts.build content: "<div><p>Hello, World</p><img src='example.com'></div>"
    assert_equal "Hello, World", post_title(post)
  end

  test "blog title" do
    blog = blogs(:joel)
    assert_equal "Posts from @#{blog.name}", blog_title(blog)

    blog.title = "My blog"
    assert_equal "My blog", blog_title(blog)
  end

  test "blog_description with no bio" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.bio = nil
    assert_equal "My blog", blog_description(blog)
  end

  test "blog_description with bio" do
    blog = blogs(:joel)
    bio = <<~BIO
    Photographer

    https://pagecord.com/joel
    BIO

    assert_equal bio.strip, blog_description(blog)
  end
end
