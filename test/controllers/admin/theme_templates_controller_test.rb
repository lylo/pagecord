require "test_helper"

class Admin::ThemeTemplatesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @template = theme_templates(:minimal_mono)
  end

  test "should get index" do
    get admin_theme_templates_url

    assert_response :success
    assert_select "h1", text: "Theme Templates"
  end

  test "should get new" do
    get new_admin_theme_template_url

    assert_response :success
  end

  test "should create template" do
    assert_difference("ThemeTemplate.count") do
      post admin_theme_templates_url, params: {
        theme_template: {
          name: "New Template",
          custom_css: ".blog { color: red; }",
          position: 5
        }
      }
    end

    assert_redirected_to admin_theme_templates_path
  end

  test "should not create template without required fields" do
    assert_no_difference("ThemeTemplate.count") do
      post admin_theme_templates_url, params: {
        theme_template: { name: "", custom_css: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_admin_theme_template_url(@template)

    assert_response :success
  end

  test "should update template" do
    patch admin_theme_template_url(@template), params: {
      theme_template: { name: "Updated Name" }
    }

    assert_redirected_to admin_theme_templates_path
    assert_equal "Updated Name", @template.reload.name
  end

  test "should destroy template" do
    assert_difference("ThemeTemplate.count", -1) do
      delete admin_theme_template_url(@template)
    end

    assert_redirected_to admin_theme_templates_path
  end

  test "should show template" do
    get admin_theme_template_url(@template)

    assert_response :success
    assert_select "h1", text: @template.name
  end

  test "should reject non-admin users" do
    login_as users(:vivian)

    get admin_theme_templates_url

    assert_redirected_to root_path
  end
end
