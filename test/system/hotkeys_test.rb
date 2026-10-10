require "application_system_test_case"

class HotkeysTest < ApplicationSystemTestCase
  setup do
    sign_in users(:vivian)
  end

  test "holding shift reveals the nav hotkeys and a hotkey follows its link" do
    keyboard.key_down(:shift).perform
    assert_selector "nav kbd", text: "G"

    keyboard.send_keys("g").key_up(:shift).perform
    assert_current_path app_pages_path
    assert_no_selector "nav kbd", text: "G"
  end

  test "a hotkey opens the blog menu and its items take hotkeys of their own" do
    keyboard.key_down(:shift).send_keys("m").perform
    assert_selector "a[data-hotkey='b'] kbd", text: "B"

    keyboard.send_keys("b").key_up(:shift).perform
    assert_current_path app_blogs_path
  end

  test "the posts list takes hotkeys for its tabs, search and a new post" do
    keyboard.key_down(:shift).send_keys("d").key_up(:shift).perform
    assert_selector ".btn-group-item-active", text: "Drafts"

    keyboard.key_down(:shift).send_keys("f").key_up(:shift).perform
    assert_selector "[data-search-target='input']:focus"

    page.execute_script("document.activeElement.blur()")
    keyboard.key_down(:shift).send_keys("n").key_up(:shift).perform
    assert_current_path new_app_post_path
  end

  test "the pages list takes hotkeys for its tabs and a new page" do
    sign_in users(:joel)
    visit app_pages_path

    keyboard.key_down(:shift).send_keys("d").key_up(:shift).perform
    assert_selector ".btn-group-item-active", text: "Drafts"

    keyboard.key_down(:shift).send_keys("n").key_up(:shift).perform
    assert_current_path new_app_page_path
  end

  test "the top waiting comment takes hotkeys to reply and approve" do
    sign_in users(:joel)
    visit app_comments_path

    keyboard.key_down(:shift).send_keys("r").key_up(:shift).perform
    assert_selector "textarea[data-hotkey='r']:focus"

    page.execute_script("document.activeElement.blur()")
    keyboard.key_down(:shift).send_keys("y").key_up(:shift).perform
    assert page.has_content?("Comment approved.", wait: 2)
  end

  test "shift types normally in a text field until it is double-tapped" do
    visit new_app_post_path
    find_field("post[title]").click

    keyboard.key_down(:shift).send_keys("g").key_up(:shift).perform
    assert_field "post[title]", with: "G"

    keyboard.key_down(:shift).key_up(:shift).key_down(:shift).key_up(:shift).perform
    assert_selector "nav kbd", text: "G"

    keyboard.key_down(:shift).send_keys("g").key_up(:shift).perform
    assert_current_path app_pages_path
  end

  private
    def sign_in(user)
      visit access_request_verification_path(user.access_requests.create!.token_digest)
      assert_current_path app_posts_path
    end

    def keyboard
      page.driver.browser.action
    end
end
