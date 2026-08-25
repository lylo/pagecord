require "test_helper"

class Admin::ThemeTemplates::FixturesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "downloads templates as yaml fixtures" do
    get admin_theme_templates_fixtures_path

    assert_response :success
    assert_equal "text/yaml", @response.media_type
    fixtures = YAML.safe_load(@response.body)
    assert_includes fixtures.keys, theme_templates(:minimal_mono).name.parameterize(separator: "_")
  end
end
