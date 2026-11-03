require "test_helper"

class App::Settings::AudienceControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "shows subscriber count when show_metrics is enabled" do
    get app_settings_audience_url

    assert_response :success
    assert_select "p", text: /Your blog has 1 email subscriber/
  end

  test "hides subscriber count when show_metrics is disabled" do
    @blog.update!(show_metrics: false)

    get app_settings_audience_url

    assert_response :success
    assert_select "p", text: /Your blog has/, count: 0
  end

  test "a lapsed subscriber can still download the subscriber list" do
    @user.subscription.update!(next_billed_at: 1.day.ago)

    get app_settings_audience_url

    assert_response :success
    assert_select "a[href=?]", app_settings_subscribers_path(format: :csv)
  end

  test "shows comments settings" do
    get app_settings_audience_url

    assert_response :success
    assert_select "input[name='blog[comments_enabled]']"
  end

  test "should update show_subscription_in_header" do
    patch app_settings_audience_url, params: { blog: { show_subscription_in_header: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_subscription_in_header
  end

  test "should update show_subscription_in_footer" do
    patch app_settings_audience_url, params: { blog: { show_subscription_in_footer: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_subscription_in_footer
  end

  test "should update subscription_description" do
    patch app_settings_audience_url, params: { blog: { subscription_description: "  Letters from the coast, now and then  " } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "Letters from the coast, now and then", @blog.reload.subscription_description
  end

  test "should clear a blank subscription_description" do
    @blog.update!(subscription_description: "Letters from the coast")

    patch app_settings_audience_url, params: { blog: { subscription_description: " " } }, as: :turbo_stream

    assert_nil @blog.reload.subscription_description
  end

  test "should update show_metrics" do
    patch app_settings_audience_url, params: { blog: { show_metrics: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_metrics
  end

  test "should not allow non-subscribed user to update subscription location settings" do
    login_as users(:vivian)

    patch app_settings_audience_url, params: {
      blog: {
        show_subscription_in_header: false,
        show_subscription_in_footer: false,
        subscription_description: "Letters from the coast"
      }
    }, as: :turbo_stream

    blog = users(:vivian).blog.reload
    assert blog.show_subscription_in_header
    assert blog.show_subscription_in_footer
    assert_nil blog.subscription_description
  end

  test "re-renders the audience page with an error when the form text is too long" do
    patch app_settings_audience_url, params: { blog: { subscription_description: "a" * 201 } }

    assert_response :unprocessable_entity
    assert_select ".field-error", text: /too long/
    assert_nil @blog.reload.subscription_description
  end
end
