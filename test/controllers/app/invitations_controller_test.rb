require "test_helper"

class App::InvitationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "a subscriber creates an invite code" do
    login_as users(:annie)

    assert_difference -> { users(:annie).invitations.count } do
      post app_invitations_path
    end
    assert_redirected_to app_invitations_path

    follow_redirect!
    assert_select "code", users(:annie).invitations.last.code
  end

  test "a writer without invitations cannot create one" do
    login_as users(:vivian)

    assert_no_difference -> { Invitation.count } do
      post app_invitations_path
    end
  end

  test "redeemed codes show who redeemed them and when" do
    login_as users(:joel)

    get app_invitations_path

    assert_select "a", text: blogs(:vivian).display_name
    assert_match "Redeemed on #{invitations(:redeemed).redeemed_at.to_date.to_formatted_s(:long)}", response.body
  end
end
