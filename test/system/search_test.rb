require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    @user = users(:vivian)
    access_request = @user.access_requests.create!
    @user.blog.update!(features: [ "admin_search" ])

    visit verify_access_request_url(token: access_request.token_digest)

    assert_current_path app_posts_path

    @user.blog.posts.create!(title: "Rails Tutorial", content: "Learning Rails framework", tags_string: "rails, web")
    @user.blog.posts.create!(title: "Python Guide", content: "Learning Python programming", tags_string: "python, backend")
    @user.blog.posts.create!(title: "Draft Post", content: "This is a draft", status: :draft)
  end

  test "search functionality works with keyboard shortcuts" do
    visit app_posts_path

    # Test Cmd+K opens search
    find("body").send_keys([ :command, "k" ])
    assert_selector "[data-search-target='input']", visible: true

    # Type search term
    fill_in "search", with: "Rails"

    assert_text "Rails Tutorial"
    assert_no_text "Python Guide"
  end

  test "search icon toggles search interface" do
    visit app_posts_path

    # Click search icon to open
    click_button title: "Search posts"
    assert_selector "[data-search-target='input']", visible: true

    # Type search term
    fill_in "search", with: "Python"

    assert_text "Python Guide"
    assert_no_text "Rails Tutorial"

    # Click X button to close and clear search
    click_button title: "Close search"
    assert_selector "[data-search-target='input']", visible: false

    # Should show all posts again
    assert_text "Rails Tutorial"
    assert_text "Python Guide"
  end

  test "escape key clears search and closes interface" do
    visit app_posts_path

    # Open search
    click_button title: "Search posts"

    # Type search term
    fill_in "search", with: "Rails"

    assert_text "Rails Tutorial"
    assert_no_text "Python Guide"

    # Press escape to clear and close
    find("[data-search-target='input']").send_keys(:escape)

    # Should show all posts again and hide search
    assert_text "Rails Tutorial"
    assert_text "Python Guide"
    assert_selector "[data-search-target='container']", visible: false
  end

  test "search includes draft posts" do
    visit app_posts_path

    click_button title: "Search posts"
    fill_in "search", with: "draft"

    assert_text "Draft Post"
    assert_text "🖋️ Drafts" # Should show drafts section
  end

  test "search by tags works" do
    visit app_posts_path

    click_button title: "Search posts"
    fill_in "search", with: "rails"

    assert_text "Rails Tutorial"
    assert_no_text "Python Guide"
  end

  test "empty search shows all posts" do
    visit app_posts_path

    click_button title: "Search posts"
    fill_in "search", with: "Rails"

    # Should only show Rails post
    assert_text "Rails Tutorial"
    assert_no_text "Python Guide"

    # Clear search
    fill_in "search", with: ""

    # Should show all posts
    assert_text "Rails Tutorial"
    assert_text "Python Guide"
  end

  private

  def login_as(user)
    visit new_session_path
    fill_in "session[email]", with: user.email
    fill_in "session[access_token]", with: "test-token"
    click_on "Sign in"
  end
end
