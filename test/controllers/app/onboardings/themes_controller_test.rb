require "test_helper"

class App::Onboardings::ThemesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "should apply a theme template" do
    template = theme_templates(:minimal_mono)

    patch app_onboarding_theme_path, params: { template_id: template.id }, as: :turbo_stream

    assert_response :no_content
    @blog = @user.blog.reload
    assert_equal template, @blog.theme_template
    assert_equal 1, @blog.theme_template_version
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "stream_layout", @blog.layout
  end

  test "switching templates leaves nothing behind from the previous one" do
    patch app_onboarding_theme_path, params: { template_id: theme_templates(:cardashian).id }, as: :turbo_stream
    patch app_onboarding_theme_path, params: { template_id: theme_templates(:minimal_mono).id }, as: :turbo_stream

    @blog = @user.blog.reload
    assert_equal "base", @blog.theme
    assert_nil @blog.custom_theme_bg_light
  end

  test "should put a blog back to the classic design" do
    @user.blog.apply_design(theme_templates(:cardashian))

    patch app_onboarding_theme_path, params: { template_id: "" }, as: :turbo_stream

    assert_response :no_content
    @blog = @user.blog.reload
    assert_nil @blog.theme_template
    assert_nil @blog.theme_template_version
    assert_equal "base", @blog.theme
    assert_equal "stream_layout", @blog.layout
    assert_nil @blog.custom_theme_bg_light
  end
end
