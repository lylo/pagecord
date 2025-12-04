require "test_helper"
require "mocha/minitest"

class BlogsHelperTest < ActionView::TestCase
  include BlogsHelper

  test "blog title" do
    blog = blogs(:joel)
    assert_equal "Posts from @#{blog.subdomain}", blog_title(blog)

    blog.title = "My blog"
    assert_equal "My blog", blog_title(blog)
  end

  test "blog title with seo_title set" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.seo_title = "Custom SEO Title"
    assert_equal "Custom SEO Title", blog_title(blog)
  end

  test "blog title prioritizes seo_title over title" do
    blog = blogs(:joel)
    blog.title = "Display Title"
    blog.seo_title = "SEO Title"
    assert_equal "SEO Title", blog_title(blog)
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

  test "blog title with home page" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.update! home_page: posts(:about)
    assert_equal "My blog", blog_title(blog)
  end
end
