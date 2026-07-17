require "test_helper"

class TurnstileVerificationTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TURNSTILE_ENABLED"] = "true"
    ENV["TURNSTILE_SECRET_KEY"] = "secret"
  end

  teardown do
    ENV.delete("TURNSTILE_ENABLED")
    ENV.delete("TURNSTILE_SECRET_KEY")
  end

  test "allows a token Cloudflare confirms" do
    stub_siteverify(success: true, body: { "success" => true })

    assert_difference "User.count", 1 do
      post signups_url, params: signup_params
    end
  end

  test "blocks a token Cloudflare rejects" do
    stub_siteverify(success: true, body: { "success" => false })

    assert_no_difference "User.count" do
      post signups_url, params: signup_params
    end
  end

  test "blocks a blank token" do
    assert_no_difference "User.count" do
      post signups_url, params: signup_params(token: "")
    end
  end

  # Fails open. Turnstile sits on top of the honeypot, form timing and rate
  # limits, so an outage must cost spam rather than signups.
  test "allows the request when siteverify refuses the connection" do
    HTTParty.stubs(:post).raises(Errno::ECONNREFUSED)

    assert_difference "User.count", 1 do
      post signups_url, params: signup_params
    end
  end

  test "allows the request when siteverify times out" do
    HTTParty.stubs(:post).raises(Net::ReadTimeout)

    assert_difference "User.count", 1 do
      post signups_url, params: signup_params
    end
  end

  # The likeliest outage shape: HTTParty doesn't raise on 5xx, so an HTML error
  # page would otherwise parse to a String and block every signup.
  test "allows the request when siteverify returns a 502" do
    stub_siteverify(success: false, body: "<html>bad gateway</html>")

    assert_difference "User.count", 1 do
      post signups_url, params: signup_params
    end
  end

  private

    def stub_siteverify(success:, body:)
      response = mock("response")
      response.stubs(:success?).returns(success)
      response.stubs(:parsed_response).returns(body)
      HTTParty.stubs(:post).returns(response)
    end

    def signup_params(token: "a-token")
      {
        user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] },
        rendered_at: signed_rendered_at,
        "cf-turnstile-response" => token
      }
    end
end
