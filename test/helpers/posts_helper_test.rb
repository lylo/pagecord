require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  setup do
    @blog = blogs(:joel)
    @blog.update!(features: [ "home_page" ])
    # Clear existing posts to avoid fixture interference
    @blog.posts.destroy_all
    @post1 = @blog.posts.create!(title: "First Post", content: "Content 1", status: :published, published_at: 2.days.ago)
    @post2 = @blog.posts.create!(title: "Second Post", content: "Content 2", status: :published, published_at: 1.day.ago)
  end

  test "process_liquid_tags returns original content when no tags present" do
    page = @blog.pages.build(content: "Just plain text content")
    result = process_liquid_tags(page)

    assert_equal "Just plain text content", result.strip
  end

  test "process_liquid_tags processes posts tag" do
    page = @blog.pages.build(content: "Here are the posts: {% posts limit: 2 %}")
    result = process_liquid_tags(page)

    assert_includes result, "Second Post"
    assert_includes result, "First Post"
  end

  test "process_liquid_tags processes tags tag" do
    @post1.update!(tag_list: [ "ruby", "rails" ])
    page = @blog.pages.build(content: "Tags: {% tags %}")
    result = process_liquid_tags(page)

    assert_includes result, "ruby"
    assert_includes result, "rails"
  end

  test "process_liquid_tags handles syntax errors gracefully" do
    page = @blog.pages.build(content: "Bad syntax: {% posts")
    result = process_liquid_tags(page)

    # Should return original content on error
    assert_equal "Bad syntax: {% posts", result.strip
  end

  test "process_liquid_tags works with multiple tags" do
    @post1.update!(tag_list: [ "ruby" ])
    page = @blog.pages.build(content: "{% posts limit: 1 %} and {% tags %}")
    result = process_liquid_tags(page)

    assert_includes result, "Second Post"
    assert_includes result, "ruby"
  end

  test "process_liquid_tags only shows visible posts" do
    hidden_post = @blog.posts.create!(title: "Hidden", content: "Hidden", status: :published, hidden: true, published_at: Time.current)
    draft_post = @blog.posts.create!(title: "Draft", content: "Draft", status: :draft, published_at: Time.current)

    page = @blog.pages.build(content: "{% posts limit: 10 %}")
    result = process_liquid_tags(page)

    assert_includes result, "Second Post"
    assert_includes result, "First Post"
    assert_not_includes result, "Hidden"
    assert_not_includes result, "Draft"
  end

  test "process_liquid_tags does not process liquid tags for regular posts" do
    post = @blog.posts.build(content: "Post with {% posts %} tag", is_page: false)
    result = process_liquid_tags(post)

    # Liquid tag should appear literally
    assert_equal "Post with {% posts %} tag", result.strip
    assert_not_includes result, "First Post"
  end

  test "process_liquid_tags only processes for pages" do
    # Regular post should not process liquid tags
    regular_post = @blog.posts.build(content: "{% posts %}", is_page: false)
    result = process_liquid_tags(regular_post)
    assert_equal "{% posts %}", result.strip

    # Page should process liquid tags
    page = @blog.pages.build(content: "{% posts %}")
    result = process_liquid_tags(page)
    assert_includes result, "First Post"
  end
end
