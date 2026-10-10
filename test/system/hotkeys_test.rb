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
    assert_selector "a[data-hotkey='v'] kbd", text: "V"
    keyboard.key_up(:shift).perform
  end

  test "the posts list takes hotkeys for its tabs and a new post" do
    keyboard.key_down(:shift).send_keys("d").key_up(:shift).perform
    assert_selector ".btn-group-item-active", text: "Drafts"

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

  test "analytics takes hotkeys for its periods and the arrow keys step through them" do
    sign_in users(:joel)
    visit app_analytics_path

    keyboard.key_down(:shift).send_keys("y").key_up(:shift).perform
    assert_selector ".btn-group-item-active", text: "Year"

    keyboard.send_keys(:arrow_left).perform
    assert_selector "span.min-w-32", text: (Date.current.year - 1).to_s
  end

  test "each settings card takes a hotkey" do
    visit app_settings_path

    keyboard.key_down(:shift).send_keys("e").key_up(:shift).perform
    assert_current_path app_settings_appearance_path

    keyboard.key_down(:shift).send_keys("r").key_up(:shift).perform
    assert_selector ".btn-group-item-active", text: "Ready-made design"
  end

  test "escape leaves the editor's text so a hotkey can save the draft" do
    visit new_app_post_path
    find_field("post[title]").send_keys("Keyboard draft")
    find("lexxy-editor .lexxy-editor__content").send_keys("Written without the mouse", :escape)
    assert_no_selector "lexxy-editor .lexxy-editor__content:focus"

    keyboard.key_down(:shift).send_keys("d").key_up(:shift).perform
    assert_current_path app_posts_path(tab: "drafts")
    assert_text "Keyboard draft"
  end

  test "escape leaves writing mode before it leaves the text" do
    visit new_app_post_path
    editor = find("lexxy-editor .lexxy-editor__content")
    editor.send_keys("Deep in thought", [ :meta, :shift, "f" ])
    assert_selector "html[data-writing-mode]"

    editor.send_keys(:escape)
    assert_no_selector "html[data-writing-mode]"
    assert_selector "lexxy-editor .lexxy-editor__content:focus"

    editor.send_keys(:escape)
    assert_no_selector "lexxy-editor .lexxy-editor__content:focus"
  end

  test "question mark opens a screen's help" do
    visit app_settings_navigation_items_path

    keyboard.key_down(:shift).send_keys("/").key_up(:shift).perform
    assert_selector "dialog[open]"
  end

  test "command period opens the settings panel from inside the text" do
    visit new_app_post_path
    find("lexxy-editor .lexxy-editor__content").send_keys("Thinking", [ :meta, "." ])
    assert_selector "[data-settings-panel-target='panel'][data-open]"

    page.driver.browser.action.send_keys(:escape).perform
    assert_no_selector "[data-settings-panel-target='panel'][data-open]"
  end

  test "command s saves a draft from inside the text" do
    visit new_app_post_path
    find_field("post[title]").send_keys("Saved mid-sentence")
    find("lexxy-editor .lexxy-editor__content").send_keys("Still typing", [ :meta, "s" ])

    assert_current_path app_posts_path(tab: "drafts")
    assert_text "Saved mid-sentence"
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
