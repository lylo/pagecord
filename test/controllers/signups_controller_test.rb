require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and redirect to posts path" do
    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: { user: { email: "test@example.com", blog_attributes: { name: "testuser" } }, rendered_at: 6.seconds.ago.to_i }
      end
    end

    assert_redirected_to thanks_signups_path

    assert_equal "testuser", User.last.blog.name
    assert_equal "test@example.com", User.last.email
    assert_not User.last.marketing_consent
  end

  test "should create user with marketing consent" do
    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: { user: { email: "test@example.com", blog_attributes: { name: "testuser" }, marketing_consent: true }, rendered_at: 6.seconds.ago.to_i }
      end
    end

    assert_redirected_to thanks_signups_path
    assert User.last.marketing_consent
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      assert_emails 0 do
        post signups_url, params: { user: { email: "", blog_attributes: { name: "" } }, rendered_at: 6.seconds.ago.to_i }
      end
    end

    assert_response :unprocessable_entity
  end

  test "should not create user if honeypot field is populated" do
    assert_no_difference("User.count") do
      post signups_url, params: { email_confirmation: "test@example.com", user: { email: "test@example.com", blog_attributes: { name: "testuser" } } }
    end

    assert_redirected_to new_signup_path
    assert_equal "Sorry, that didn't work. Contact support if the problem persists", flash[:error]
  end

  test "should not create user if form rendered and submitted within 5 seconds" do
    assert_no_difference("User.count") do
      post signups_url, params: { email_confirmation: "test@example.com", user: { email: "test@example.com", blog_attributes: { name: "testuser" } }, rendered_at: 3.seconds.ago.to_i }
    end

    assert_redirected_to new_signup_path
    assert_equal "Sorry, that didn't work. Contact support if the problem persists", flash[:error]
  end
end
