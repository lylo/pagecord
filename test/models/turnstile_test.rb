require "test_helper"

class TurnstileTest < ActiveSupport::TestCase
  setup do
    ENV["TURNSTILE_SECRET_KEY"] = "secret"
  end

  teardown do
    ENV.delete("TURNSTILE_SECRET_KEY")
  end

  test "true for a token Cloudflare confirms" do
    stub_siteverify(success: true, body: { "success" => true })

    assert Turnstile.verify?("a-token", remote_ip: "203.0.113.1")
  end

  test "false for a token Cloudflare rejects" do
    stub_siteverify(success: true, body: { "success" => false })

    assert_not Turnstile.verify?("a-token", remote_ip: "203.0.113.1")
  end

  test "false for a blank token without calling Cloudflare" do
    HTTParty.expects(:post).never

    assert_not Turnstile.verify?("", remote_ip: "203.0.113.1")
    assert_not Turnstile.verify?(nil, remote_ip: "203.0.113.1")
  end

  # Fails open. Turnstile sits on top of the honeypot, form timing and rate
  # limits, so an outage must cost spam rather than signups.
  test "true when siteverify refuses the connection" do
    HTTParty.stubs(:post).raises(Errno::ECONNREFUSED)

    assert Turnstile.verify?("a-token", remote_ip: "203.0.113.1")
  end

  test "true when siteverify times out" do
    HTTParty.stubs(:post).raises(Net::ReadTimeout)

    assert Turnstile.verify?("a-token", remote_ip: "203.0.113.1")
  end

  # The likeliest outage shape: HTTParty doesn't raise on 5xx, so an HTML error
  # page would otherwise parse to a String and block every request.
  test "true when siteverify returns a 502" do
    stub_siteverify(success: false, body: "<html>bad gateway</html>")

    assert Turnstile.verify?("a-token", remote_ip: "203.0.113.1")
  end

  private

    def stub_siteverify(success:, body:)
      response = mock("response")
      response.stubs(:success?).returns(success)
      response.stubs(:parsed_response).returns(body)
      HTTParty.stubs(:post).returns(response)
    end
end
