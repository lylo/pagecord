require "test_helper"

class App::Settings::AudienceControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "shows subscriber count when show_metrics is enabled" do
    get app_settings_audience_index_url

    assert_response :success
    assert_select "p", text: /Your blog has 1 email subscriber/
  end

  test "hides subscriber count when show_metrics is disabled" do
    @blog.update!(show_metrics: false)

    get app_settings_audience_index_url

    assert_response :success
    assert_select "p", text: /Your blog has/, count: 0
  end

  test "hides comments settings when the feature is disabled" do
    get app_settings_audience_index_url

    assert_response :success
    assert_select "input[name='blog[comments_enabled]']", count: 0
  end

  test "shows comments settings when the feature is enabled" do
    @user.update!(features: [ "comments" ])

    get app_settings_audience_index_url

    assert_response :success
    assert_select "input[name='blog[comments_enabled]']"
  end
end
