require "test_helper"

class App::Settings::CustomCode::DesignCopiesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    @template = theme_templates(:minimal_mono)
    @blog.apply_design(@template)
    login_as @user
  end

  test "offers the stylesheet and the copy when a design is applied" do
    get app_settings_custom_code_url

    assert_select "a[href*='themes/minimal-mono']", text: "View CSS"
    assert_select "form[action=?]", app_settings_custom_code_design_copy_path
  end

  test "copies the design's css into custom css and goes back to classic" do
    post app_settings_custom_code_design_copy_url

    assert_redirected_to app_settings_custom_code_path
    @blog.reload
    assert_nil @blog.theme_template
    assert_includes @blog.custom_css, "12px monospace journal"
  end

  test "is not for free users" do
    vivian = users(:vivian)
    vivian.blog.apply_design(@template)
    login_as vivian

    post app_settings_custom_code_design_copy_url

    assert_response :not_found
    assert_equal @template, vivian.blog.reload.theme_template
  end
end
