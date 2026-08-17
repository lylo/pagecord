require "test_helper"

class App::Settings::SubscribersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "downloads confirmed subscribers as CSV" do
    get app_settings_subscribers_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", @response.media_type
    assert_match "fred@example.com", @response.body    # confirmed
    assert_no_match "geoff@gmail.com", @response.body   # unconfirmed excluded
  end
end
