require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should create user and redirect to posts path" do
    assert_difference("User.count") do
      assert_emails 1 do
        post users_url, params: { user: { username: "testuser", email: "test@example.com" } }
      end
    end

    assert_redirected_to user_posts_path(User.last.username)

    assert_equal "testuser", User.last.username
    assert_equal "test@example.com", User.last.email
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      assert_emails 0 do
        post users_url, params: { user: { username: "", email: "" } }
      end
    end

    assert_response :unprocessable_entity
  end
end