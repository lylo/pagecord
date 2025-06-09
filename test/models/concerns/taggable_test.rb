# frozen_string_literal: true

require "test_helper"

class TaggableTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
    @post = Post.create!(
      title: "Test Post",
      content: ActionText::RichText.new(body: "Test content"),
      blog: @blog
    )
  end

  test "should parse comma-separated tags" do
    @post.tags_string = "rails, javascript, ruby"
    assert_equal [ "javascript", "rails", "ruby" ], @post.tag_list
  end

  test "should parse space-separated tags" do
    @post.tags_string = "rails javascript ruby"
    assert_equal [ "javascript", "rails", "ruby" ], @post.tag_list
  end

  test "should handle mixed separators" do
    @post.tags_string = "rails, javascript ruby hotwire"
    assert_equal [ "hotwire", "javascript", "rails", "ruby" ], @post.tag_list
  end

  test "should normalize tags to lowercase" do
    @post.tags_string = "Rails, JavaScript, RUBY"
    assert_equal [ "javascript", "rails", "ruby" ], @post.tag_list
  end

  test "should remove duplicates" do
    @post.tags_string = "rails, Rails, RAILS, javascript"
    assert_equal [ "javascript", "rails" ], @post.tag_list
  end

  test "should strip whitespace" do
    @post.tags_string = "  rails  ,  javascript  ,  ruby  "
    assert_equal [ "javascript", "rails", "ruby" ], @post.tag_list
  end

  test "should reject blank tags" do
    @post.tags_string = "rails, , javascript, "
    assert_equal [ "javascript", "rails" ], @post.tag_list
  end

  test "should convert tag_list to comma-separated string" do
    @post.tag_list = [ "rails", "javascript", "ruby" ]
    assert_equal "rails, javascript, ruby", @post.tags_string
  end

  test "should return empty string for empty tag_list" do
    @post.tag_list = []
    assert_equal "", @post.tags_string
  end

  test "should validate tag format" do
    @post.tag_list = [ "rails", "javascript-framework", "ruby123" ]
    assert @post.valid?

    @post.tag_list = [ "rails!", "@javascript", "ruby with spaces" ]
    assert_not @post.valid?
    assert_includes @post.errors[:tag_list].first, "invalid tags"
  end

  test "should allow valid tag characters" do
    @post.tag_list = [ "rails", "javascript-framework", "ruby123", "web-dev", "API" ]
    assert @post.valid?
  end

  test "should reject invalid tag characters" do
    invalid_tags = [ "rails!", "@javascript", "ruby with spaces", "tag#hash", "tag.dot" ]
    invalid_tags.each do |tag|
      @post.tag_list = [ tag ]
      assert_not @post.valid?, "Tag '#{tag}' should be invalid"
    end
  end

  test "should sort tags alphabetically on save" do
    @post.tags_string = "zebra, apple, banana"
    @post.save!
    assert_equal [ "apple", "banana", "zebra" ], @post.tag_list
  end

  test "should find posts tagged with specific tags" do
    post1 = Post.create!(
      title: "Rails Post",
      content: ActionText::RichText.new(body: "About Rails"),
      blog: @blog,
      tag_list: [ "rails", "ruby" ]
    )

    post2 = Post.create!(
      title: "JavaScript Post",
      content: ActionText::RichText.new(body: "About JavaScript"),
      blog: @blog,
      tag_list: [ "javascript", "web" ]
    )

    post3 = Post.create!(
      title: "Full Stack Post",
      content: ActionText::RichText.new(body: "About full stack"),
      blog: @blog,
      tag_list: [ "rails", "javascript" ]
    )

    rails_posts = Post.tagged_with("rails")
    assert_includes rails_posts, post1
    assert_includes rails_posts, post3
    assert_not_includes rails_posts, post2

    js_posts = Post.tagged_with("javascript")
    assert_includes js_posts, post2
    assert_includes js_posts, post3
    assert_not_includes js_posts, post1
  end

  test "should find posts tagged with any of the specified tags" do
    post1 = Post.create!(
      title: "Rails Post",
      content: ActionText::RichText.new(body: "About Rails"),
      blog: @blog,
      tag_list: [ "rails", "ruby" ]
    )

    post2 = Post.create!(
      title: "JavaScript Post",
      content: ActionText::RichText.new(body: "About JavaScript"),
      blog: @blog,
      tag_list: [ "javascript", "web" ]
    )

    post3 = Post.create!(
      title: "Python Post",
      content: ActionText::RichText.new(body: "About Python"),
      blog: @blog,
      tag_list: [ "python", "django" ]
    )

    web_posts = Post.tagged_with_any("rails", "javascript")
    assert_includes web_posts, post1
    assert_includes web_posts, post2
    assert_not_includes web_posts, post3
  end

  test "should get all unique tags" do
    Post.create!(
      title: "Post 1",
      content: ActionText::RichText.new(body: "Content 1"),
      blog: @blog,
      tag_list: [ "rails", "ruby" ]
    )

    Post.create!(
      title: "Post 2",
      content: ActionText::RichText.new(body: "Content 2"),
      blog: @blog,
      tag_list: [ "javascript", "rails" ]
    )

    all_tags = Post.all_tags
    assert_includes all_tags, "rails"
    assert_includes all_tags, "ruby"
    assert_includes all_tags, "javascript"
    assert_equal all_tags, all_tags.sort # Should be sorted
  end
end
