require "test_helper"

class App::Blogs::TrashControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should get trash with discarded blogs" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    blog.discard!

    with_multiple_blogs_for(user) do
      login_as user

      get app_blogs_trash_url

      assert_response :success
      assert_select "h1", "Blog trash"
      assert_match blog.display_name, response.body
      assert_select "form[action='#{app_blog_restoration_path(blog)}']"
      assert_select "form[action='#{app_blog_path(blog)}']"
    end
  end

  test "should show empty trash message" do
    user = users(:joel)

    with_multiple_blogs_for(user) do
      login_as user

      get app_blogs_trash_url

      assert_response :success
      assert_match "Your trash is empty", response.body
    end
  end

  test "should empty trash" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    blog.discard!

    with_multiple_blogs_for(user) do
      login_as user

      assert_difference -> { Blog.with_discarded.count }, -1 do
        delete app_blogs_trash_url
      end

      assert_redirected_to app_blogs_trash_url
      assert_equal "Trash was successfully emptied", flash[:notice]
    end
  end

  test "empty trash only removes current user's discarded blogs" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    other_blog = blogs(:annie)
    blog.discard!
    other_blog.discard!

    with_multiple_blogs_for(user) do
      login_as user

      delete app_blogs_trash_url

      assert_not Blog.with_discarded.exists?(blog.id)
      assert other_blog.reload.discarded?
    end
  end

  test "redirects when multiple blog feature is disabled" do
    user = users(:joel)
    login_as user

    get app_blogs_trash_url
    assert_redirected_to app_root_url

    delete app_blogs_trash_url
    assert_redirected_to app_root_url
  end

  private

    def with_multiple_blogs_for(user)
      original_features = user.features
      user.update!(features: original_features | [ "multiple_blogs" ])
      yield
    ensure
      user.update!(features: original_features)
    end
end
