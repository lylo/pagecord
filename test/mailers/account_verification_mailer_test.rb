require "test_helper"

class AccountVerificationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:joel)
  end

  test "verify sends to user email" do
    email = AccountVerificationMailer.with(user: @user).verify
    assert_equal [ @user.email ], email.to
    assert_equal "Verify your Pagecord email address", email.subject
  end

  test "login sends to user email" do
    email = AccountVerificationMailer.with(user: @user).login
    assert_equal [ @user.email ], email.to
    assert_equal "Log into your Pagecord account", email.subject
  end
end
