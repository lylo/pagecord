require "test_helper"

class App::OnboardingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "should be redirect to onboarding page" do
    get app_root_path

    assert_redirected_to app_onboarding_path
  end

  test "should render the reply letter with every design" do
    get app_onboarding_path

    assert_response :success
    assert_select ".letter-sheet", ThemeTemplate.active.count + 1
    assert_select "form[action=?]", app_onboarding_completion_path
  end

  test "marks the applied design as chosen" do
    get app_onboarding_path
    assert_select "input[name=template_id][value=''][checked]"

    @user.blog.update!(theme_templates(:cardashian).appearance_attributes)
    get app_onboarding_path
    assert_select "input[name=template_id][value=?][checked]", theme_templates(:cardashian).id.to_s
  end
end
