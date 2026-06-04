require "test_helper"

class App::Blogs::RestorationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should restore discarded blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    blog.discard!

    with_multiple_blogs_for(user) do
      login_as user

      post app_blog_restoration_url(blog)

      assert_redirected_to app_blogs_trash_url
      assert_equal "#{blog.display_name} was successfully restored", flash[:notice]
      assert_not blog.reload.discarded?
    end
  end

  test "should not restore when user is at blog limit" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    blog.discard!
    user.blogs.create!(subdomain: "joelphotos")

    with_multiple_blogs_for(user) do
      login_as user

      post app_blog_restoration_url(blog)

      assert_redirected_to app_blogs_trash_url
      assert_equal "You can't restore this blog because you've already reached your blog limit", flash[:alert]
      assert blog.reload.discarded?
    end
  end

  test "should not restore blog belonging to another user" do
    user = users(:joel)
    other_blog = blogs(:annie)
    other_blog.discard!

    with_multiple_blogs_for(user) do
      login_as user

      post app_blog_restoration_url(other_blog)

      assert_response :not_found
      assert other_blog.reload.discarded?
    end
  end

  test "redirects when multiple blog feature is disabled" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    blog.discard!
    login_as user

    post app_blog_restoration_url(blog)
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
