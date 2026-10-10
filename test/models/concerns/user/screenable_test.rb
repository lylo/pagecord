require "test_helper"

class User::ScreenableTest < ActiveSupport::TestCase
  setup do
    ENV["CLEANTALK_AUTH_KEY"] = "test-key"
    @user = users(:annie)
  end

  teardown do
    ENV.delete("CLEANTALK_AUTH_KEY")
  end

  test "a refused sender fails screening with CleanTalk's codes" do
    CleanTalk.stubs(:check_newuser).returns({ "allow" => 0, "codes" => "FORBIDDEN BL" })

    @user.screen(ip: "1.2.3.4", user_agent: "Mozilla/5.0")

    assert @user.screening_failed?
    assert_equal({ "cleantalk" => "FORBIDDEN BL" }, @user.screening.failed_checks)
  end

  test "an allowed sender passes screening" do
    CleanTalk.stubs(:check_newuser).returns({ "allow" => 1, "codes" => "" })

    @user.screen(ip: "1.2.3.4", user_agent: "Mozilla/5.0")

    assert_not @user.screening_failed?
  end
end
