require "application_system_test_case"

class HotkeysTest < ApplicationSystemTestCase
  setup do
    access_request = users(:vivian).access_requests.create!
    visit access_request_verification_path(access_request.token_digest)
    assert_current_path app_posts_path
  end

  test "holding shift reveals the nav hotkeys and a hotkey follows its link" do
    keyboard.key_down(:shift).perform
    assert_selector "nav kbd", text: "G"

    keyboard.send_keys("g").key_up(:shift).perform
    assert_current_path app_pages_path
    assert_no_selector "nav kbd", text: "G"
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
    def keyboard
      page.driver.browser.action
    end
end
