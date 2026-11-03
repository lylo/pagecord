require "test_helper"

class App::InvitationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    Invitation.stubs(:required?).returns(true)
  end

  test "a subscriber creates an invite code" do
    login_as users(:annie)

    assert_difference -> { users(:annie).invitations.count } do
      post app_invitations_path
    end
    assert_redirected_to app_invitations_path

    follow_redirect!
    assert_select "code", users(:annie).invitations.last.code
    assert_select "span", "9 of 10 remaining"
  end

  test "a writer who has used their allowance still sees it, without the create button" do
    User.any_instance.stubs(:invitation_allowance).returns(1)
    users(:annie).invitations.create!
    login_as users(:annie)

    get app_invitations_path

    assert_select "span", "0 of 1 remaining"
    assert_select "button", text: "Create invite code", count: 0
  end

  test "an unused code can be deleted" do
    login_as users(:joel)

    assert_difference -> { Invitation.count }, -1 do
      delete app_invitation_path(invitations(:unused))
    end
    assert_redirected_to app_invitations_path
  end

  test "a redeemed code can't be deleted" do
    login_as users(:joel)

    assert_no_difference -> { Invitation.count } do
      delete app_invitation_path(invitations(:redeemed))
    end
    assert_response :not_found
  end

  test "someone else's code can't be deleted" do
    login_as users(:annie)

    assert_no_difference -> { Invitation.count } do
      delete app_invitation_path(invitations(:unused))
    end
    assert_response :not_found
  end

  test "a writer without invitations cannot create one" do
    login_as users(:vivian)

    assert_no_difference -> { Invitation.count } do
      post app_invitations_path
    end
  end

  test "writers can't reach invites while signup is open" do
    Invitation.stubs(:required?).returns(false)
    login_as users(:annie)

    get app_invitations_path
    assert_redirected_to app_posts_path

    follow_redirect!
    assert_select "a[href=?]", app_invitations_path, count: 0
  end

  test "an admin can make codes before signup closes" do
    Invitation.stubs(:required?).returns(false)
    login_as users(:joel)

    get app_invitations_path

    assert_response :success
    assert_select "a[href=?]", app_invitations_path
  end

  test "redeemed codes show who redeemed them and when" do
    login_as users(:joel)

    get app_invitations_path

    assert_select "a", text: blogs(:vivian).display_name
    assert_match "Redeemed on #{invitations(:redeemed).redeemed_at.to_date.to_formatted_s(:long)}", response.body
  end
end
