require "test_helper"

class Admin::Moderation::ScreeningsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "lists false positives under the blog that was reviewed, and missed spam" do
    users(:joel).create_screening!(failed_checks: { cleantalk: "FORBIDDEN BL" })
    blogs(:joel).update!(reviewed_at: nil)
    blogs(:joel_notes).update!(reviewed_at: 1.day.ago)
    AccountTombstone.create!(reason: :spam, failed_checks: {}, subdomain: "missedone", signed_up_at: 2.days.ago, deleted_at: 1.day.ago)

    get admin_moderation_screenings_path

    assert_response :success
    assert_match "@#{blogs(:joel_notes).subdomain}", response.body
    assert_match "cleantalk FORBIDDEN BL", response.body
    assert_match "@missedone", response.body
  end

  test "says when there is nothing to compare yet" do
    get admin_moderation_screenings_path

    assert_match "Nothing to compare yet", response.body
  end
end
