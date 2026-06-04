require "test_helper"

class App::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "premium user can create a second blog and it becomes current" do
    user = users(:annie)
    login_as user

    assert_difference -> { user.blogs.reload.count } do
      post app_blogs_url, params: { blog: { subdomain: "anniessecond", title: "Annie Second" } }
    end

    blog = user.blogs.find_by!(subdomain: "anniessecond")
    assert_equal blog.id, session[:current_blog_id]
    assert_redirected_to app_root_url
  end

  test "free user cannot create a second blog" do
    user = users(:vivian)
    login_as user

    assert_no_difference -> { user.blogs.reload.count } do
      post app_blogs_url, params: { blog: { subdomain: "viviansecond" } }
    end

    assert_response :unprocessable_entity
  end

  test "switching blogs uses the selected blog in new post context" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    login_as user

    post switch_app_blog_url(blog)
    assert_equal blog.id, session[:current_blog_id]

    get new_app_post_url

    assert_response :success
    assert_select "input[name='context_blog_id'][value='#{blog.id}']"
  end

  test "creates posts on the selected blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
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

  test "trashes posts on the selected blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    post = blog.posts.create!(title: "Trash me", content: "Hello")
    login_as user
    post switch_app_blog_url(blog)

    assert_difference -> { blog.posts.discarded.count } do
      post app_posts_trash_url, params: { post_token: post.token }
    end

    assert post.reload.discarded?
  end

  test "deleting selected blog falls back to remaining blog" do
    user = users(:joel)
    blog = blogs(:joel_notes)
    login_as user
    post switch_app_blog_url(blog)

    delete app_blog_url(blog)

    assert blog.reload.discarded?
    assert_equal user.blog.id, session[:current_blog_id]
    assert_redirected_to app_blogs_url
  end

  test "cannot delete the only blog with a direct request" do
    user = users(:vivian)
    blog = user.blog
    login_as user

    assert_no_difference -> { user.blogs.reload.count } do
      delete app_blog_url(blog)
    end

    assert_not blog.reload.discarded?
    assert_redirected_to app_blogs_url
    assert_equal "You must have at least one blog", flash[:alert]
  end
end
