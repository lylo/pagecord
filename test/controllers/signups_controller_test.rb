require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and redirect to posts path" do
    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: { user: { username: "testuser", email: "test@example.com" } }
      end
    end

    assert_redirected_to thanks_signups_path

    assert_equal "testuser", User.last.username
    assert_equal "test@example.com", User.last.email
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      assert_emails 0 do
        post signups_url, params: { user: { username: "", email: "" } }
      end
    end

    assert_response :unprocessable_entity
  end
end