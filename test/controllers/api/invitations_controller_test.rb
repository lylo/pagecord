require "test_helper"

class Api::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"
  end

  test "create makes an invite code for the blog's owner" do
    assert_difference -> { users(:joel).invitations.count } do
      post "/invitations", headers: auth_header("test_api_key_for_fixtures")
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal users(:joel).invitations.order(:created_at).last.code, json["code"]
    assert_equal "http://example.com/signups/new?code=#{json["code"]}", json["url"]
  end

  test "create refuses anyone but an admin" do
    blog = blogs(:annie)
    blog.user.update!(trial_ends_at: 30.days.from_now)

    assert_no_difference -> { Invitation.count } do
      post "/invitations", headers: auth_header(blog.generate_api_key!)
    end

    assert_response :forbidden
  end

  private

    def auth_header(token)
      { "Authorization" => "Bearer #{token}" }
    end
end
