require "test_helper"

class App::Settings::ExportsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should create export with default html format" do
    assert_difference -> { Blog::Export.count } do
      assert_enqueued_with(job: BlogExportJob) do
        post app_settings_exports_path
      end
    end

    export = Blog::Export.last
    assert export.html?
    assert_redirected_to app_settings_exports_path
    assert_equal "Export started", flash[:notice]
  end

  test "should create export with markdown format" do
    assert_difference -> { Blog::Export.count } do
      assert_enqueued_with(job: BlogExportJob) do
        post app_settings_exports_path, params: { blog_export: { format: "markdown" } }
      end
    end

    export = Blog::Export.last
    assert export.markdown?
    assert_redirected_to app_settings_exports_path
    assert_equal "Export started", flash[:notice]
  end

  test "should create export with html format explicitly" do
    assert_difference -> { Blog::Export.count } do
      assert_enqueued_with(job: BlogExportJob) do
        post app_settings_exports_path
      end
    end

    export = Blog::Export.last
    assert export.html?
    assert_redirected_to app_settings_exports_path
    assert_equal "Export started", flash[:notice]
  end

  test "should destroy export" do
    export = @blog.exports.create!

    assert_difference -> { Blog::Export.count }, -1 do
      delete app_settings_export_path(export)
    end

    assert_redirected_to app_settings_exports_path
    assert_equal "Export deleted", flash[:notice]
  end

  test "should not allow destroying other user's export" do
    other_blog = blogs(:annie)
    other_export = other_blog.exports.create!

    assert_no_difference -> { Blog::Export.count } do
      delete app_settings_export_path(other_export)
      assert_response :not_found
    end
  end
end
