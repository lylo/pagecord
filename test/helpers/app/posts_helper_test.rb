require "test_helper"

class App::PostsHelperTest < ActionView::TestCase
  setup do
    @blog = blogs(:joel)
  end

  # publish_button_text tests

  test "publish_button_text for new post" do
    post = @blog.posts.build(content: "Test")
    assert_equal "Publish Post", publish_button_text(post)
  end

  test "publish_button_text for new page" do
    page = @blog.pages.build(title: "Test Page", content: "Test")
    assert_equal "Publish Page", publish_button_text(page)
  end

  test "publish_button_text for new home page with model_name override" do
    home_page = @blog.pages.build(title: "Home", content: "Test")
    assert_equal "Publish Home Page", publish_button_text(home_page, model_name: "Home Page")
  end

  test "publish_button_text for existing draft post" do
    post = @blog.posts.create!(content: "Test", status: :draft)
    assert_equal "Publish Post", publish_button_text(post)
  end

  test "publish_button_text for existing draft page" do
    page = @blog.pages.create!(title: "Draft Page", content: "Test", status: :draft)
    assert_equal "Publish Page", publish_button_text(page)
  end

  test "publish_button_text for existing published post" do
    post = @blog.posts.create!(content: "Test", status: :published)
    assert_equal "Update Post", publish_button_text(post)
  end

  test "publish_button_text for existing published page" do
    page = @blog.pages.create!(title: "Published Page", content: "Test", status: :published)
    assert_equal "Update Page", publish_button_text(page)
  end

  test "publish_button_text for existing published home page with model_name override" do
    home_page = @blog.pages.create!(title: "Home", content: "Test", status: :published)
    @blog.update!(home_page_id: home_page.id)
    assert_equal "Update Home Page", publish_button_text(home_page, model_name: "Home Page")
  end

  # draft_button_text tests

  test "draft_button_text for new post" do
    post = @blog.posts.build(content: "Test")
    assert_equal "Save Draft", draft_button_text(post)
  end

  test "draft_button_text for new page" do
    page = @blog.pages.build(title: "Test Page", content: "Test")
    assert_equal "Save Draft", draft_button_text(page)
  end

  test "draft_button_text for new home page with model_name override" do
    home_page = @blog.pages.build(title: "Home", content: "Test")
    assert_equal "Save Draft", draft_button_text(home_page, model_name: "Home Page")
  end

  test "draft_button_text for existing draft post" do
    post = @blog.posts.create!(content: "Test", status: :draft)
    assert_equal "Update Draft", draft_button_text(post)
  end

  test "draft_button_text for existing draft page" do
    page = @blog.pages.create!(title: "Draft Page", content: "Test", status: :draft)
    assert_equal "Update Draft", draft_button_text(page)
  end

  test "draft_button_text for existing published post" do
    post = @blog.posts.create!(content: "Test", status: :published)
    assert_equal "Unpublish", draft_button_text(post)
  end

  test "draft_button_text for existing published page" do
    page = @blog.pages.create!(title: "Published Page", content: "Test", status: :published)
    assert_equal "Unpublish", draft_button_text(page)
  end

  test "draft_button_text for existing published home page with model_name override" do
    home_page = @blog.pages.create!(title: "Home", content: "Test", status: :published)
    @blog.update!(home_page_id: home_page.id)
    assert_equal "Unpublish", draft_button_text(home_page, model_name: "Home Page")
  end
end
