require "application_system_test_case"

class ModerationQueueTest < ApplicationSystemTestCase
  setup do
    Blog.update_all(reviewed_at: Time.current)
    blogs(:annie).update!(reviewed_at: nil)
    blogs(:elliot).update!(reviewed_at: nil)

    access_request = users(:joel).access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)
  end

  test "reviews blogs from the keyboard" do
    visit admin_moderation_blogs_path
    find("body").send_keys("j")
    reviewed = find("article[data-selected]")[:id]

    find("body").send_keys("n")

    assert_selector "article", count: 1
    assert_no_selector "article##{reviewed}"
    assert_selector "article[data-selected]"
    assert page.has_content?("marked as not spam", wait: 2)
  end
end
