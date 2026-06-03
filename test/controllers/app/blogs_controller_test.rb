require "test_helper"

class App::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "premium user can create a second blog and it becomes current" do
    user = users(:annie)
    with_multiple_blogs_for(user) do
      login_as user

      assert_difference -> { user.blogs.reload.count } do
        post app_blogs_url, params: { blog: { subdomain: "anniessecond", title: "Annie Second" } }
      end

      blog = user.blogs.find_by!(subdomain: "anniessecond")
      assert_equal blog.id, session[:current_blog_id]
      assert_redirected_to app_root_url
    end
  end

  test "free user can see manage blogs upsell" do
    user = users(:vivian)
    with_multiple_blogs_for(user) do
      login_as user

      get app_blogs_url

      assert_response :success
      assert_select "h1", "Your blogs"
      assert_select "a[href='#{new_app_blog_path}']", count: 0
      assert_match "add a second blog", response.body
      assert_select "a[href='#{app_settings_subscriptions_path}']", text: "Subscribe to Pagecord Premium"
    end
  end

  test "trial user can see manage blogs upsell" do
    user = users(:vivian)
    user.update!(trial_ends_at: 5.days.from_now)

    with_multiple_blogs_for(user) do
      login_as user

      get app_blogs_url

      assert_response :success
      assert_select "h1", "Your blogs"
      assert_select "a[href='#{new_app_blog_path}']", count: 0
      assert_match "add a second blog", response.body
    end
  end

  test "delete blog buttons require confirmation" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    with_multiple_blogs_for(user) do
      login_as user

      get app_blogs_url

      assert_response :success
      assert_select "form[action='#{app_blog_path(blog)}'][method='post'][data-turbo-confirm=?]", "Are you sure you want to delete #{blog.display_name}?" do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", "Delete"
      end
    end
  end

  test "free user cannot create a second blog" do
    user = users(:vivian)
    with_multiple_blogs_for(user) do
      login_as user

      get new_app_blog_url
      assert_redirected_to app_blogs_url
      assert_equal "Subscribe to create another blog", flash[:alert]

      assert_no_difference -> { user.blogs.reload.count } do
        post app_blogs_url, params: { blog: { subdomain: "viviansecond" } }
      end

      assert_redirected_to app_blogs_url
    end
  end

  test "switching blogs uses the selected blog in new post context" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    with_multiple_blogs_for(user) do
      login_as user

      post switch_app_blog_url(blog)
      assert_equal blog.id, session[:current_blog_id]

      get new_app_post_url

      assert_response :success
      assert_select "input[name='context_blog_id'][value='#{blog.id}']"
    end
  end

  test "creates posts on the selected blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    with_multiple_blogs_for(user) do
      login_as user
      post switch_app_blog_url(blog)

      assert_difference -> { blog.posts.reload.count } do
        post app_posts_url, params: {
          context_blog_id: blog.id,
          post: { title: "Second Blog Post", content: "Hello" }
        }
      end

      assert_equal "Second Blog Post", blog.posts.last.title
    end
  end

  test "trashes posts on the selected blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    post = blog.posts.create!(title: "Trash me", content: "Hello")
    with_multiple_blogs_for(user) do
      login_as user
      post switch_app_blog_url(blog)

      assert_difference -> { blog.posts.discarded.count } do
        post app_posts_trash_url, params: { post_token: post.token }
      end

      assert post.reload.discarded?
    end
  end

  test "deleting selected blog falls back to remaining blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    with_multiple_blogs_for(user) do
      login_as user
      post switch_app_blog_url(blog)

      delete app_blog_url(blog)

      assert blog.reload.discarded?
      assert_equal user.blog.id, session[:current_blog_id]
      assert_redirected_to app_blogs_url
    end
  end

  test "cannot delete the only blog with a direct request" do
    user = users(:vivian)
    blog = user.blog
    with_multiple_blogs_for(user) do
      login_as user

      assert_no_difference -> { user.blogs.reload.count } do
        delete app_blog_url(blog)
      end

      assert_not blog.reload.discarded?
      assert_redirected_to app_blogs_url
      assert_equal "You must have at least one blog", flash[:alert]
    end
  end

  test "multiple blog UI redirects when feature is disabled" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    login_as user

    get app_blogs_url
    assert_redirected_to app_root_url

    get new_app_blog_url
    assert_redirected_to app_root_url

    post app_blogs_url, params: { blog: { subdomain: "blockedcreate" } }
    assert_redirected_to app_root_url

    post switch_app_blog_url(blog)
    assert_redirected_to app_root_url

    delete app_blog_url(blog)
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
