require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    @user = users(:vivian)
    access_request = @user.access_requests.create!

    visit access_request_verification_path(access_request.token_digest)

    assert_current_path app_posts_path

    @user.blog.posts.create!(title: "Rails Tutorial", content: "Learning Rails framework", tags_string: "rails, web")
    @user.blog.posts.create!(title: "Python Guide", content: "Learning Python programming", tags_string: "python, backend")
    @user.blog.posts.create!(title: "Draft Post", content: "This is a draft", status: :draft)
    @user.blog.posts.create!(title: "Bill Gates Biography", content: "Bill Gates founded Microsoft and is now a philanthropist", tags_string: "biography, tech")
    @user.blog.posts.create!(title: "About Bill", content: "Bill works at our company as a developer", tags_string: "team, staff")
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
end
