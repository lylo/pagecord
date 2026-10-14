require "test_helper"

class App::Onboardings::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "sets a password for an account without one" do
    post app_onboarding_password_path, params: { user: { password: "a long password", password_confirmation: "a long password" } }, as: :turbo_stream

    assert_response :success
    assert @user.reload.authenticate("a long password")
  end

  test "refuses a password that doesn't match its confirmation" do
    post app_onboarding_password_path, params: { user: { password: "a long password", password_confirmation: "a different one" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not @user.reload.has_password?
  end

  test "can't change a password that's already set" do
    @user.update!(password: "the original password")

    post app_onboarding_password_path, params: { user: { password: "a long password", password_confirmation: "a long password" } }, as: :turbo_stream

    assert_response :forbidden
    assert @user.reload.authenticate("the original password")
  end
end
