require "application_system_test_case"

class TagsTest < ApplicationSystemTestCase
  # Rename and remove are covered by the controller test. What only exists in the
  # browser is the swap from label to form and back.
  setup do
    user = users(:joel)
    access_request = user.access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)

    visit app_posts_tags_path
  end

  test "renaming a tag inline" do
    assert_no_field "new_name"

    within_photography_row do
      click_on "Rename photography"
      fill_in "new_name", with: "photos"
      click_on "Save"
    end

    assert_text "Tag was renamed to photos"
    assert_text "photos"
    assert_no_text "photography"
  end

  test "cancelling puts the tag name back" do
    within_photography_row do
      click_on "Rename photography"
      fill_in "new_name", with: "something-else"
      click_on "Cancel"

      assert_no_field "new_name"
      assert_text "photography"

      click_on "Rename photography"
      assert_field "new_name", with: "photography"
    end
  end

  private

    def within_photography_row(&block)
      within find("[data-controller='inline-edit']", text: "photography"), &block
    end
end
