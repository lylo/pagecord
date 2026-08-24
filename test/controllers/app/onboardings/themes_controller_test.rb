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
    assert_includes @blog.custom_css, "12px monospace journal"
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "stream_layout", @blog.layout
  end
end
