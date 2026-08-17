require "test_helper"

class App::Settings::ApiControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "premium user can generate and revoke an api key" do
    login_as users(:joel)

    post app_settings_api_path
    assert_response :see_other
    assert users(:joel).blog.reload.api_key_digest.present?

    delete app_settings_api_path
    assert_redirected_to app_settings_api_path
    assert_nil users(:joel).blog.reload.api_key_digest
  end

  test "free user cannot generate an api key" do
    user = users(:vivian)
    assert user.on_free_plan?
    login_as user

    post app_settings_api_path

    assert_response :not_found
    assert_nil user.blog.reload.api_key_digest
  end

  test "free user cannot revoke an api key" do
    user = users(:vivian)
    login_as user

    delete app_settings_api_path

    assert_response :not_found
  end
end
