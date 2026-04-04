require "test_helper"

class AccountVerificationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:joel)
  end

  test "login does not route to cloudflare without feature" do
    stub_cloudflare_env do
      email = AccountVerificationMailer.with(user: @user).login
      refute_instance_of CloudflareEmail::DeliveryMethod, email.delivery_method
    end
  end

  test "login routes to cloudflare when feature is enabled" do
    @user.blog.update!(features: [ "cloudflare_email" ])

    stub_cloudflare_env do
      email = AccountVerificationMailer.with(user: @user).login
      assert_instance_of CloudflareEmail::DeliveryMethod, email.delivery_method
    end
  end

  test "verify does not route to cloudflare even with feature enabled" do
    @user.blog.update!(features: [ "cloudflare_email" ])

    stub_cloudflare_env do
      email = AccountVerificationMailer.with(user: @user).verify
      refute_instance_of CloudflareEmail::DeliveryMethod, email.delivery_method
    end
  end

  private

    def stub_cloudflare_env
      ENV["CLOUDFLARE_EMAIL_API_TOKEN"] = "test-token"
      ENV["CLOUDFLARE_ACCOUNT_ID"] = "test-account"
      yield
    ensure
      ENV.delete("CLOUDFLARE_EMAIL_API_TOKEN")
      ENV.delete("CLOUDFLARE_ACCOUNT_ID")
    end
end
