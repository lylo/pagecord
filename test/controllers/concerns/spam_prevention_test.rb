require "test_helper"

# Wiring of the spam prevention checks through a real controller. The checks
# themselves are unit tested in test/models (Turnstile, SuspiciousEmail).
class SpamPreventionTest < ActionDispatch::IntegrationTest
  test "allows a signup that passes the Turnstile challenge" do
    with_turnstile_enabled do
      Turnstile.stubs(:verify?).returns(true)

      assert_difference "User.count", 1 do
        post signups_url, params: signup_params
      end
    end
  end

  test "blocks a signup that fails the Turnstile challenge" do
    with_turnstile_enabled do
      Turnstile.stubs(:verify?).returns(false)

      assert_no_difference "User.count" do
        post signups_url, params: signup_params
      end
    end
  end

  # A failed challenge is usually a real person who can retry, so it re-renders
  # the form and says so, rather than reusing the generic spam rejection.
  test "a failed challenge asks the visitor to complete the security check" do
    with_turnstile_enabled do
      Turnstile.stubs(:verify?).returns(false)

      post signups_url, params: signup_params

      assert_response :unprocessable_entity
      assert_includes @response.body, "Please complete the security check"
    end
  end

  test "blocks a signup with a suspicious email" do
    assert_no_difference "User.count" do
      post signups_url, params: signup_params(email: "s.p.a.m.m.e.r@gmail.com")
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "There&#39;s an issue signing you up"
  end

  private

    def with_turnstile_enabled
      ENV["TURNSTILE_ENABLED"] = "true"
      yield
    ensure
      ENV.delete("TURNSTILE_ENABLED")
    end

    def signup_params(email: "test@example.com")
      {
        user: { email: email, blogs_attributes: [ { subdomain: "testuser" } ] },
        rendered_at: signed_rendered_at,
        "cf-turnstile-response" => "a-token"
      }
    end
end
