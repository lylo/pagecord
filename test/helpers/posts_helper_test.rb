require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  setup do
    @blog = blogs(:joel)
    # Clear existing posts to avoid fixture interference
    @blog.posts.destroy_all
    @post1 = @blog.posts.create!(title: "First Post", content: "Content 1", status: :published, published_at: 2.days.ago)
    @post2 = @blog.posts.create!(title: "Second Post", content: "Content 2", status: :published, published_at: 1.day.ago)
  end

  test "process_liquid_tags returns original content when no tags present" do
    content = "Just plain text content"
    result = process_liquid_tags(content, @blog)

    assert_equal "Just plain text content", result
  end

  test "process_liquid_tags processes posts tag" do
    content = "Here are the posts: {% posts limit: 2 %}"
    result = process_liquid_tags(content, @blog)

    assert_includes result, "Second Post"
    assert_includes result, "First Post"
  end

  test "process_liquid_tags processes tag_list tag" do
    @post1.update!(tag_list: [ "ruby", "rails" ])
    content = "Tags: {% tag_list %}"
    result = process_liquid_tags(content, @blog)

    assert_includes result, "ruby"
    assert_includes result, "rails"
  end

  test "process_liquid_tags handles syntax errors gracefully" do
    content = "Bad syntax: {% posts"
    result = process_liquid_tags(content, @blog)

    # Should return original content on error
    assert_equal "Bad syntax: {% posts", result
  end

  test "process_liquid_tags works with multiple tags" do
    @post1.update!(tag_list: [ "ruby" ])
    content = "{% posts limit: 1 %} and {% tag_list %}"
    result = process_liquid_tags(content, @blog)

    assert_includes result, "Second Post"
    assert_includes result, "ruby"
  end

  test "process_liquid_tags only shows visible posts" do
    hidden_post = @blog.posts.create!(title: "Hidden", content: "Hidden", status: :published, hidden: true, published_at: Time.current)
    draft_post = @blog.posts.create!(title: "Draft", content: "Draft", status: :draft, published_at: Time.current)

    content = "{% posts limit: 10 %}"
    result = process_liquid_tags(content, @blog)

    assert_includes result, "Second Post"
    assert_includes result, "First Post"
    assert_not_includes result, "Hidden"
    assert_not_includes result, "Draft"
  end
end
