require "test_helper"

class App::Onboardings::CompletionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "should complete onboarding" do
    post app_onboarding_completion_path

    assert_redirected_to app_root_path
    assert_equal "Welcome to Pagecord!", flash[:notice]
    assert @user.reload.onboarding_complete?
  end
end
